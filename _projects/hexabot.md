---
pillar: control-robotics
title: "Hexabot Locomotion Control — Kinematics, MuJoCo Modeling & Procedural Gait Simulation"
permalink: /projects/hexabot/
excerpt: "A fully physics-simulated hexapod built from analytical kinematics, a custom MuJoCo XML model, and a real-time procedural tripod gait controller."
header:
  teaser: /assets/images/projects/Hexabot/cover.jpg
  image: /assets/images/projects/Hexabot/cover.jpg
categories:
  - Mechatronics
  - Controls
  - Simulation
tags:
  - robotics
  - simulation
  - mujoco
  - forward-kinematics
  - inverse-kinematics
  - gait-generation
  - locomotion
---

**Timeframe:** Sep 2025 – Dec 2025  
**Tools:** Python, MuJoCo, NumPy, analytical kinematics, gait generation, real-time control  
**Outcome:** A real-time MuJoCo hexapod simulation that walks, turns, arc-walks, changes body height, and runs entirely from closed-form FK/IK rather than motion clips or numerical solvers

---

## Project Overview

This project was a full bottom-up build of a six-legged walking robot in MuJoCo, starting from the leg geometry and kinematic equations and ending in a real-time interactive simulation with stable tripod gait locomotion. The goal was not only to make a hexapod move, but to build the entire locomotion stack in a way that stayed mathematically transparent. That meant defining the body layout explicitly, building the MuJoCo XML from the robot's geometry, deriving closed-form forward and inverse kinematics for each leg, and then using those solvers inside a procedural gait controller that could respond continuously to keyboard commands. The final result was a simulation that could stand, walk forward and backward, turn in place, combine turning with translation into arc-walking, and adjust torso height, all without pre-recorded trajectories, black-box numerical IK, or baked animation clips.

What made the project technically valuable was the way each layer depended on the previous one. The XML model was only correct if the frame conventions matched the math. The FK solver was only useful if it reproduced the same geometric chain defined in MuJoCo. The IK solver was only robust if it respected the same link lengths, joint ranges, and leg-base placement used by the model. The gait controller was only stable if the kinematic targets stayed inside the physically realizable workspace and if the actuator model in MuJoCo was tuned to behave like a real servo-driven robot. The project therefore became an exercise in making the model, the math, and the controller agree exactly, with each interface checked against the next rather than treated as an isolated implementation task.

---

## Mathematical Model & Leg Geometry

The mathematical foundation of the robot was a repeated 3-DOF leg model attached to a rigid torso. Each of the six legs used a coxa-femur-tibia chain, where the coxa joint provided yaw about the local vertical axis, and the femur and tibia joints provided pitch motion in the leg plane. The physical link lengths were defined directly in the project configuration and matched the MuJoCo XML: a `25 mm` coxa stub offset the leg away from the body, the femur length was `100 mm`, and the tibia length was `100 mm`. The six leg bases were distributed symmetrically on the torso, with front, mid, and rear pairs on the left and right sides, and each coxa joint was given a different neutral facing direction so the front legs pointed diagonally forward, the mid legs pointed sideways, and the rear legs pointed diagonally backward.

From a math standpoint, this created a clean decomposition. The coxa joint handled horizontal placement of the leg by rotating the leg around the torso `z` axis, while the femur and tibia reduced to a planar two-link problem once the target was projected into the rotated leg plane. This separation is what made a closed-form inverse kinematics solution practical and fast enough to run per leg every control frame. It also made the system easy to debug, because horizontal aiming and planar reach could be reasoned about independently.

![D-F Parameter Diagram](/assets/images/projects/Hexabot/df-parameter.png)

The original kinematic derivation was expressed using homogeneous transformations and D-H style frame chaining. That representation helped formalize the reference frames and joint ordering before implementation. In practice, the final Python FK code was written more directly in terms of rotation matrices and segment offsets because that maps more naturally onto MuJoCo's body-tree representation. Even so, the D-H derivation remained useful as the consistency check that the final solver and the MuJoCo model were using the same geometry, axis ordering, and sign conventions. That bridge between symbolic derivation and implementation was important because a single frame mismatch in a six-legged robot multiplies quickly into gait asymmetry, unstable contact, or mirrored leg motion.

---

## MuJoCo XML Build

The MuJoCo model in `assets/hexapod.xml` encoded the robot as a free-floating torso with six repeated leg subtrees. The torso itself was represented as a rigid box body with a `freejoint`, allowing the robot to move dynamically rather than being pinned to the world. Each leg began at a rigidly attached body such as `leg0_base` or `leg4_base`, then passed through a coxa hinge joint, a femur hinge joint, and a tibia hinge joint. The XML body offsets matched the analytical model exactly: the femur body was placed `0.025 m` along the coxa local `+X` axis, the tibia body was placed `0.10 m` along the femur local `+Z`, and the foot contact site was placed another `0.10 m` along the tibia local `+Z`.

The model was built with physically meaningful actuator and joint parameters rather than idealized kinematic teleportation. Each joint used position actuators with different proportional gains for coxa, femur, and tibia, reflecting the fact that yaw response, load-bearing femur motion, and foot-placement control do not need identical stiffness. The XML also included viscous damping, rotor armature, and Coulomb friction loss so the joint response felt closer to a hobby servo system than to a perfect simulator-only actuator. Torque was capped at `±2.5 N·m`, roughly the scale of a small servo such as a Dynamixel XL430, which meant the gait had to stay inside a realistic force and inertia envelope rather than relying on unrealistically strong joints. In effect, the controller was not commanding ideal joint angles into a massless skeleton. It was sending targets into a physically limited actuator layer whose gains, damping, and torque saturation all shaped what motions were actually achievable.

The contact model mattered as much as the kinematics. The ground plane used high enough friction to support stable foot contact during the tripod gait, and each foot tip was represented by a site with a touch sensor so contact information could be read back from simulation. The XML also included torso orientation and gyro sensing through `framequat` and `gyro` sensors, making the model extensible toward future feedback-based stabilization work. In short, the MuJoCo build was not just a visual skeleton. It was a physically parameterized robot model whose geometry, joint limits, sensor definitions, and actuator dynamics were all chosen to support the control stack above it.

---

## Forward Kinematics

The forward kinematics implementation in [fk.py](/Users/jamesz/Desktop/UCB/239_Spider/src/fk.py) computes foot positions in the torso frame directly from the joint angles of each leg. The chain is compact but precise. For a given leg, the solver starts at the torso-frame leg base position, rotates the coxa link by `Rot_Z(theta_coxa)`, applies the `25 mm` coxa offset, then rotates the femur by `Rot_Y(theta_femur)` and the tibia by `Rot_Y(theta_tibia)` before adding the femur and tibia segment vectors. In code, the tip position becomes the base position plus the coxa rotation applied to the coxa offset and the nested femur-tibia chain. That exact order is important because it mirrors the XML hierarchy, not a generic textbook chain.

The FK solver was used for more than just getting foot coordinates. It became the nominal stance generator, the calibration baseline, and the debugging tool for validating whether the controller and IK were producing plausible target poses. During startup, the robot was first allowed to settle physically in MuJoCo for roughly seven seconds so gravity, joint damping, and contact forces could bring it into a consistent resting configuration. After that warm-up, the controller recalibrated its stance reference using the actual settled joint configuration rather than a purely theoretical pose. That calibration step depended on FK to convert the settled joint angles into the torso-frame foot reference positions that the gait generator would later use as the neutral stance. This reduced the gap between nominal geometry and simulated physical reality, which in turn made the first walking cycle much more stable and predictable.

The FK module also included a torso-to-world transformation step that converted torso-frame feet into world-frame coordinates using a quaternion-derived rotation matrix. That was useful for inspection and for understanding how foot placement changed once the free-floating torso began pitching or rolling in the simulator. The round-trip consistency between FK and IK was strong enough that the README reports FK -> IK -> FK error on the order of `1e-15 m`, which is effectively machine precision and a good sign that the frame conventions and link geometry were implemented coherently.

---

## Inverse Kinematics

The inverse kinematics implementation in [ik.py](/Users/jamesz/Desktop/UCB/239_Spider/src/ik.py) solved the leg analytically rather than numerically. This mattered because the gait controller calls IK for all six legs every control frame, so solve speed, determinism, and stability all benefit from avoiding iterative optimization. The solution began by expressing the target foot position relative to the leg base in the torso frame. The coxa angle was then solved immediately using `atan2(y, x)`, which points the leg toward the foot in the horizontal plane. After that, the solver rotated the target back into the coxa-aligned leg plane and subtracted the coxa stub offset so the remaining problem reduced to a 2D femur-tibia triangle.

At that point the femur and tibia angles were solved by geometry. The solver formed the effective distance from femur joint to foot target, checked reachability, and then used the law of cosines to obtain the femur solution branch. A second trigonometric step recovered the tibia angle from the projected geometry. The implementation supported elbow-up and elbow-down branches, but the controller consistently used the elbow-down solution because that matched the robot's natural crouched walking posture. The code also optionally clamped the resulting angles to the joint ranges imported from the same config used by the XML, which prevented the controller from commanding postures outside the physically modeled actuator limits.

![IK Derivation](/assets/images/projects/Hexabot/IK.png)

The important design choice here was not only that the IK was analytical, but that it was written in a way that respected the actual model build. The joint names, leg-base positions, coxa offset, femur length, tibia length, and allowable joint intervals all came from shared project configuration. That reduced the risk of a silent mismatch between "math world" and "simulation world," which is a common failure mode in robot projects where the solver is derived independently from the model file. It also made the solver easier to trust during gait development, because failures could be traced to unreachable foot targets or aggressive trajectory design rather than to uncertainty about whether the leg model itself was wrong.

---

## Control Pipeline

The overall control pipeline was built as a layered loop running at two timescales. At the top level, user input from the keyboard selected desired forward and turning commands, plus discrete actions such as stand, idle, body-up, and body-down. Those commands were consumed by a high-level locomotion controller running at `60 Hz`. The controller kept continuous `fwd` and `turn` states, applied independent acceleration and deceleration ramps, advanced the tripod gait phase, generated desired foot trajectories, and then dispatched leg-by-leg IK to convert those targets into joint-angle commands. Those joint targets were sent through a MuJoCo interface layer that mapped joint names to actuator control channels and then advanced the physics simulation with `8` MuJoCo substeps per control frame, corresponding to a `500 Hz` physics integration rate.

![Control Pipeline](/assets/images/projects/Hexabot/ControlPipeline.png)

That separation between control rate and physics rate was important. The locomotion policy did not need to run at the full physics timestep, but the contact simulation benefited from a smaller MuJoCo timestep for smoother ground interaction. This gave the project a more realistic control architecture: a controller that computes commands at a moderate rate, and a physics engine that integrates the underlying dynamics more frequently.

The controller was explicitly velocity based rather than mode based. Instead of switching among separate "walk," "turn," and "arc" states, it accepted `fwd` and `turn` in `[-1, 1]` and ramped both axes continuously. That meant holding `W` alone produced forward walking, holding `A` or `D` alone produced turning in place, and holding `W + A` or `W + D` naturally produced arc-walking because both stride components remained active at once. Releasing keys decayed the relevant axes smoothly back to zero, so the robot slowed down rather than freezing abruptly. This made the simulation feel more like a velocity-commanded machine and less like a scripted animation system. It also created a cleaner software architecture, because gait generation only needed one continuously parameterized stride model rather than separate hard-switched behaviors for each movement mode.

---

## Gait Generation & Body Control

The gait itself was a diagonal tripod gait, with legs `(0, 3, 4)` in one tripod and legs `(1, 2, 5)` in the other, separated by a phase offset of `0.5`. At any point in the cycle, one tripod was in stance while the other tripod was in swing, maintaining a stable three-point support polygon. The gait frequency was set to `0.9 Hz`, the nominal stride length to `0.05 m`, the turn displacement scale to `0.04 m`, and the swing-foot lift height to `0.03 m`. The duty factor was `0.5`, giving equal stance and swing portions over one cycle.

The stance and swing trajectories were generated procedurally rather than retrieved from a trajectory file. During stance, the foot stayed on the ground and swept backward relative to the torso, generating forward propulsion. During swing, the foot moved forward while following a sinusoidal vertical lift profile, which gave a smooth bell-shaped clearance curve instead of a discontinuous lift-and-drop motion. Turning used a tangential foot displacement term computed from the leg's radial direction relative to the body, which is what allowed the same trajectory routine to handle straight walking, turning in place, and combined arc motion.

Body-height control was integrated into the same framework. After MuJoCo settling, the controller called a calibration routine that measured the actual settled torso height and stance foot depth. That meant later body-up and body-down commands adjusted torso height relative to the true resting configuration, not a guessed nominal geometry. This was a practical but important detail because it aligned the IK targets with the true simulated contact state and prevented the controller from trying to stand at a posture inconsistent with the physics-settled robot. From a control-design perspective, this also made the body-height commands feel much more deliberate: the torso was not simply being offset in configuration space, but re-targeted relative to the measured contact-compatible stance that MuJoCo had already found.

![Body Posture / Gesture Control](/assets/images/projects/Hexabot/full-gesture-control.png)

---

## Final MuJoCo Simulation Build

By the end of the project, the robot existed as a complete integrated simulation stack rather than a set of disconnected experiments. The MuJoCo world contained a free body with six three-joint legs, actuator physics, ground contact, friction, touch sensing, and IMU-like sensing. The Python stack contained a thin MuJoCo interface, a deterministic kinematics layer, and a gait controller that responded in real time to sustained keyboard commands. The posture, stepping, and turning behavior all emerged from the model and controller together. Nothing was replayed from recorded data, and nothing depended on manual frame-by-frame scripting.

That is what made the final build meaningful from a controls perspective. The robot could accept continuous user commands, convert them into velocity references, transform them into foot trajectories, solve IK leg by leg, send actuator targets into a physics model with torque and friction limits, and then recover the resulting body motion visually in simulation. The stack was compact, but every layer was explicit and inspectable. The final system also had a clear tuning structure: body geometry and joint limits lived in `assets/config.py`, gait timing and stride parameters lived in `src/controller.py`, and actuator stiffness and physical response lived in `assets/hexapod.xml`. That separation made it possible to adjust one part of the behavior, such as stride length or ramp rate, without accidentally corrupting the geometry or the physics assumptions below it.

This tuning process mattered in practice. Parameters such as `STEP_FREQ = 0.9 Hz`, `STEP_LEN = 0.05 m`, `TURN_LEN = 0.04 m`, `STEP_H = 0.03 m`, and velocity ramp rates of `3.0` for acceleration and `6.0` for deceleration were not arbitrary. They represent a compromise between responsiveness, foot clearance, and contact stability. A longer stride or faster phase rate made the robot look more energetic, but pushed the leg targets closer to workspace boundaries and increased the chance of slipping or awkward touchdown timing. A smaller stride was safer but made the gait look tentative. The final values were therefore chosen to keep the robot agile enough to demonstrate smooth interactive control while still respecting the actuator strength and the closed-form leg workspace.

---

## Final Walking Demo

The final simulation demonstrated the robot walking stably on flat ground, transitioning smoothly between stand and motion, turning without losing balance, and combining turning with translation into curved paths. The animation also showed that the tripod gait remained visually consistent and physically plausible under the chosen actuator and contact parameters. Because the controller supported held-key input rather than single-shot commands, the robot could be driven continuously in a way that felt much closer to operating a real mobile platform. Forward motion, turning, stopping, and curved walking all emerged from the same continuous control law rather than from separate canned actions.

![Hexabot Walking Demo](/assets/images/projects/Hexabot/cover.jpg)

The most important outcome of the project was not any single equation or controller parameter. It was the consistency of the whole pipeline. The math matched the XML, the XML matched the control assumptions, and the controller produced motion that the MuJoCo physics engine could actually realize. That consistency is what turned a legged-robot thought exercise into a functioning simulation platform. At the same time, the project made the current limitations very visible in a productive way. The gait still assumes flat terrain, the controller is still fundamentally open-loop at the gait level, and torso attitude is not yet actively stabilized by IMU feedback. Those gaps are now well defined, which makes the project a strong base for future extensions such as terrain adaptation, contact-aware gait timing, or full body stabilization.
