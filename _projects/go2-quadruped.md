---
pillar: control-robotics
title: "Intelligent Control of Quadruped Robot (Unitree Go2) — RL, MPC & Cooperative Manipulation"
permalink: /projects/go2-quadruped/
excerpt: "Full-stack locomotion and manipulation system on a Unitree Go2 quadruped — from RL sim-to-real transfer to a cooperative human-robot object carrying demo using onboard sensors only."
header:
  image: /assets/images/projects/Go2/cover.jpg
  teaser: /assets/images/projects/Go2/cover.jpg
categories:
  - Mechatronics
  - Controls
  - Machine Learning
tags:
  - mechatronics
  - controls
  - simulation
  - reinforcement-learning
  - mpc
  - ros2
  - quadruped
  - manipulation
  - sim-to-real
---

**Timeframe:** Sep 2025 – May 2026  
**Team:** 6 members -> 2 sub-teams (RL / MPC) -> merged into unified control stack  
**Tools:** Python, C++, MuJoCo, Isaac Lab, Pinocchio, CasADi, ROS 2 Humble, Unitree SDK, PPO, Streamlit  
**Robot:** Unitree Go2 quadruped + Unitree D1 robotic arm (6-DOF + gripper)

---

## Project Overview

This capstone began as an open-ended exploration: take a Unitree Go2 quadruped robot, implement intelligent locomotion control, and, if time allowed, tackle the robotic arm attached to its back. What started as a parallel experiment between two control philosophies, RL vs. MPC, evolved into a unified, three-layer cooperative control system capable of carrying an oversized object alongside a human, using **no external sensors or motion capture** and relying only on the robot's onboard IMU, foot force sensors, joint encoders, and arm feedback.

The final demo shows the Go2 walking in coordination with a human to carry a shared object, with intent estimated purely from the physical signals of the interaction itself.

---

## Annotated Timeline

### Milestone 1 - Scoping & Team Split
*September 2025*

The team began by defining the first concrete objective: **stable locomotion control** on the Go2. Rather than committing to a single method, we split into two parallel sub-teams to explore the two dominant paradigms in legged robot control:

- **RL Team** - train a neural network policy end-to-end in simulation using Proximal Policy Optimization (PPO), then deploy via sim-to-real transfer.
- **MPC Team** - implement a convex Model Predictive Controller based on the MIT Cheetah 3 work (Di Carlo et al., IROS 2018), which formulates locomotion as a real-time constrained quadratic program over a receding horizon.

The rationale: both approaches had published results on similar hardware, but their real-world performance on the Go2 under our constraints, with no motion capture and no external state estimation hardware, was an open question.

---

### Milestone 2 - RL Training: Walk These Ways on Isaac Lab
*October 2025*

The RL team adopted [Walk These Ways GO2](https://github.com/Teddy-Liao/walk-these-ways-go2) as the training backbone. This repository implements a PPO-based locomotion policy trained in **Isaac Gym**, with a parameterized command interface that allows runtime control of gait style, speed, and body height.

**Training setup:**
- Environment: Isaac Gym (GPU-accelerated parallel simulation, about 4096 environments simultaneously)
- Policy: PPO with a Multi-Layer Perceptron actor-critic
- Observation space: proprioceptive only - joint positions/velocities, IMU orientation, previous actions, command input
- Action space: target joint position offsets at 50 Hz
- Initial training run: **10,000 episodes** on the lab server

The simulation result looked promising in the Isaac Gym visualizer. The dog walked forward stably in a variety of gaits and responded to velocity commands.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/isaace_lab_forward_walk.mp4" type="video/mp4">
</video>
*Isaac Lab forward walking policy after the initial 10,000-episode training run.*

---

### Pivot 1 - First Real Deployment: Communication & Stability Issues
*November 2025*

Deploying the trained policy to the physical Go2 revealed two immediate problems.

**Problem 1: LCM communication channel conflicts.**  
The Unitree Go2 runs internal services, including the MCF service and Sports Mode service, that continuously send control commands to the motor controllers. During our first deployment attempts, these services were left running. They competed with our policy's commands for bandwidth and caused multiple controllers to simultaneously attempt corrections, resulting in erratic, oscillating behavior.

**Problem 2: Effective control frequency dropped to about 5 Hz.**  
Despite training at 50 Hz, the deployed policy was only executing at approximately 5 Hz because of the bandwidth contention above. This 10x frequency mismatch between training and deployment is a classic sim-to-real failure mode because the policy's timing assumptions are completely violated.

**Problem 3: Standing instability.**  
The dog had significant difficulty transitioning to a stable stand from rest. We had to issue an internal SDK stand command first and then hand off to the policy. Once standing, the policy caused continuous small hops in the static position and became unstable during turning and lateral walking.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/First_Hardware_deployment.mp4" type="video/mp4">
</video>

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/walk_these_ways_stand.mov" type="video/quicktime">
</video>
*First hardware deployment showing static hopping and poor stability during turning and lateral gait transitions.*

**Response:** We spent roughly one week re-reading the Unitree SDK documentation and community forums. The fix for the frequency issue required explicitly **disabling the MCF service and Sports Mode service** before policy deployment. These services had to be fully stopped, not merely paused, in order to release motor-controller bandwidth. We also began hyperparameter tuning and relaunched training for **20,000 episodes**.

---

### Milestone 3 - Retraining & Partial Improvement
*November-December 2025*

The 20,000-episode retrain with tuned hyperparameters showed measurable but limited improvement. Turning stability improved noticeably, and the runtime body-height command became more responsive. However, the characteristic jumping gait, short, bouncy steps instead of fluid walking, persisted.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/walk_these_ways.mp4" type="video/mp4">
</video>
*20,000-episode retrained policy with improved turning and body-height response, but the hopping gait still present.*

---

### Pivot 2 - Root Cause Found: 50 Hz Fix Changes Everything
*December 2025*

After disabling the MCF and Sports Mode services and confirming 50 Hz policy execution, the locomotion quality improved dramatically. The dog walked with a smooth, stable trot, held its heading during turning, and responded to lateral commands without oscillation. This was the single most impactful fix of the entire RL development phase. The breakthrough came not from more training data or model changes, but from correctly configuring the deployment environment to match the training assumptions.

**Key lesson:** Sim-to-real failure is often not a policy problem. It is an integration problem. Validating the complete deployment pipeline, including frequency, communication, and service conflicts, should happen before hyperparameter tuning.

---

### Pivot 3 - MPC Team: Real-Time Solver Divergence on Hardware
*December 2025*

In parallel, the MPC sub-team implemented a convex MPC locomotion controller based on the MIT Cheetah 3 formulation (Di Carlo et al., IROS 2018). The controller models the robot as a single rigid body, linearizes the equations of motion, and solves a quadratic program at each control step using **IPOPT** to compute optimal ground reaction forces, which are then mapped to joint torques via the Jacobian transpose.

In MuJoCo simulation, the controller produced clean, stable gaits with good disturbance rejection.

On real hardware, the controller failed to converge reliably. The Go2's onboard compute introduced **variable time delays** in the control loop. These delays were small enough to be negligible in simulation but large enough to cause the IPOPT solver to receive inconsistent state observations between iterations. The result was solver divergence: the QP solution would blow up into physically unrealistic ground reaction forces and violently destabilize the robot.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/mpc_deploy.mp4" type="video/mp4">
</video>
*MPC hardware deployment showing solver divergence caused by timing delay and inconsistent feedback.*

This is a known challenge with real-time MPC on legged robots: the solver must complete within a strict time budget, and any jitter in state feedback breaks the warm-start assumptions that make receding-horizon solvers tractable. Mitigations such as warm-starting, reduced horizon length, and state prediction to compensate for delay were explored but did not fully resolve the issue within the project timeline.

---

### Milestone 4 - Teams Merge: New Unified Goal
*January 2026*

With both sub-teams having hit deployment walls, we reconverged and redefined the project's scope around a more ambitious unified objective:

> **Develop a cooperative human-robot object-carrying system using only the robot's onboard sensors, where a human and the Go2, with the D1 arm attached, jointly carry an oversized object and the robot autonomously infers human intent while coordinating its body and arm accordingly.**

![Concept overview](/assets/images/projects/Go2/concept1.png)
*Unified project concept for cooperative object carrying without external sensors or teleoperation.*

The key design constraint that shaped the rest of the work was **no external devices**. No motion capture, no force/torque sensors mounted to the object, and no handheld remote. The robot had to infer the human's intent purely from signals already available on the hardware: foot force sensors, IMU, and arm joint encoders.

That constraint is what separates this approach from most published cooperative-manipulation work, which typically relies on wrist-mounted F/T sensors or external tracking.

---

### Milestone 5 - Three-Layer Control Architecture
*January 2026*

To structure the problem, we designed a **three-layer hierarchical control pipeline**:

![Control pipeline architecture](/assets/images/projects/Go2/control-pipeline.png)
*Three-layer control pipeline: intent estimation, body coordination, and low-level execution.*

| Layer | Name | Method | Role |
|---|---|---|---|
| **High** | Human Intent Estimator | CNN classifier on sensor streams | Predicts human intended motion direction from foot force, IMU, and arm encoder signals |
| **Mid** | Body Coordination Optimizer | Threshold-based hybrid controller | Decides whether to move legs, compensate with arm IK only, or both |
| **Low** | Execution Layer | RL locomotion policy + constrained IK solver | Executes leg gaits and arm joint targets |

The three sub-tasks, motion training, arm control, and full-stack integration, were divided among the team.

---

### Milestone 6 - Arm Control: SDK -> MuJoCo IK -> Pinocchio + CasADi
*January-February 2026*

The D1 robotic arm (6-DOF + gripper) required building an inverse-kinematics pipeline from scratch because the Unitree SDK only exposes low-level joint angle commands.

**Stage 1: SDK familiarization**  
We tested the official Unitree D1 SDK, including forward kinematics, multi-joint angle publishing, and driving modes. This established the baseline communication layer: the host machine connects to the arm via Ethernet, publishes joint-angle targets and a driving-mode flag (mode `0` for position control), and reads back joint states.

**Stage 2: MuJoCo Damped Least Squares IK**  
We implemented an IK solver using MuJoCo's internal Jacobian computation (`mj_jacSite`). The solver uses **Damped Least Squares (DLS)**, a regularized pseudoinverse method that avoids singularity-induced instability:

```text
Delta theta = J^T (J J^T + lambda^2 I)^-1 Delta x
```

where `lambda` is the damping factor, `J` is the `6 x n` site Jacobian, and `Delta x` is the Cartesian error. The pipeline accepted XYZ Cartesian input, computed joint deltas, published them through the SDK, and read back encoder feedback. **CycloneDDS** was used as the ROS 2 middleware bridge between the host machine and the arm.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/arm_ik.mp4" type="video/mp4">
</video>
*MuJoCo DLS IK solver enabling Cartesian XYZ control over the Unitree D1 arm.*

**Stage 3: Pinocchio + CasADi constrained IK (final)**  
The MuJoCo solver had two limitations: it lacked support for joint constraints and depended on Ethernet-only operation. We migrated to **Pinocchio** for kinematics and **CasADi** for nonlinear optimization, enabling a constrained IK formulation.

- **Gripper orientation constraint:** The end-effector was constrained to maintain a fixed reference pose, specifically the initial horizontal orientation. This was enforced as a cost term in the CasADi objective instead of a hard equality constraint, which improved convergence.
- **Partial-DOF optimization:** Because the arm only needed to pick objects from the side, full 6-DOF solving was unnecessary. We fixed proximal joints and optimized only the distal subset, reducing problem dimensionality and improving solve time.
- **Wireless operation:** We removed the Ethernet dependency by routing commands through the ROS 2 `/arm_command` node over the Jetson WiFi link.

The `/arm_command` node consolidated Cartesian target input, Pinocchio/CasADi IK solve, joint-angle array plus mode flag, Unitree SDK publishing, and physical arm execution.

The D1 has **6 active DOF plus 1 gripper**. In the final solver, proximal joints such as shoulder rotation and upper arm motion were fixed to a side-pick configuration, while distal joints such as elbow, wrist pitch, and wrist roll were optimized. The gripper joint was separately controlled via a binary open/close command.

---

### Milestone 7 - Locomotion Retraining: Isaac Lab -> MJLab, Imitation Learning
*February-March 2026*

With the unified goal defined, the locomotion policy needed to be rebuilt to support stable standing, smooth walking without the hopping artifact, and, critically, walking with the D1 arm mounted and potentially loaded.

**MJLab conversion (20x speedup):**  
We ported the Walk These Ways training stack from Isaac Gym to **Isaac Lab** and stripped out components irrelevant to our use case, such as gait switching, special actions, and curriculum scheduling. Training speed improved by more than **20x**, reducing iteration cycles from hours to minutes.

**Reward shaping additions:**

| Addition | Purpose |
|---|---|
| Minimum body height penalty | Prevents crouching and collapse |
| Foot contact reward | Encourages correct trot contact pattern |
| IMU tilt penalty | Penalizes excessive body roll and pitch |
| IMU acceleration constraint | Smooths velocity transitions and eliminates hopping |
| Domain randomization (external force) | Random pushes during training for disturbance robustness |
| Standing reward | Explicit reward for stable static stance |

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/mj_lab_train.mp4" type="video/mp4">
</video>
*MJLab training run with smooth trot gait, stable standing, and reduced hopping.*

**Imitation learning for arm-loaded walking:**  
The mounted D1 arm adds significant mass and shifts the center of mass. A policy trained on the bare Go2 model cannot reliably generalize to this configuration without retraining.

We modified the MuJoCo XML to include the arm geometry, mass distribution, and joint constraints, measured physically and cross-checked against the D1 datasheet.

![D1 arm dimensions and mass properties](/assets/images/projects/Go2/arm_dimension.jpg)
*D1 arm physical dimensions and mass properties added to the MuJoCo model for imitation learning and balance compensation.*

Training curriculum:
1. **Base policy transfer** - initialize from the trained bare-Go2 policy.
2. **Fixed arm fine-tuning** - arm held in folded position so the policy learns to compensate for added mass.
3. **Random fixed arm positions** - arm placed at a random fixed configuration at episode start so the policy learns to walk across the arm configuration space.
4. **Dynamic arm randomization** - arm position randomized every 5 seconds within an episode, simulating arm motion during a carry task. The policy had to maintain gait stability under dynamic center-of-mass shifts.

![Go2 with D1 arm mounted](/assets/images/projects/Go2/carry_start.jpg)
*Go2 with the D1 arm mounted and the carry-task hardware configuration installed.*

---

### Milestone 8 - Human Intent Estimation: Sensor Fusion + CNN Classifier
*March-April 2026*

The core research contribution of this project was **inferring human locomotion intent from physical interaction signals using only onboard sensors**.

**Sensor modalities used:**
- **Foot force sensors** - contact-force distribution shifts when a human applies force to a shared object
- **IMU (linear acceleration + angular rate)** - body perturbation caused by external forces
- **Arm joint encoders** (`/armFeedback` topic) - micro-deflections in encoder readings when force is applied to the arm or a held object, even without active motion

**Validation experiment:**  
The arm was held at a fixed position while gripping a rigid stick. A team member pushed the stick forward or backward while we logged all three sensor streams simultaneously. Multiple labeled data bags were collected for the classes "push forward," "push backward," and "no input."

![Data collection setup](/assets/images/projects/Go2/data_colection.png)
*Sensor data collection with a fixed arm, rigid object, and labeled human input directions.*

A small **1D CNN classifier** was trained on windowed sensor streams to output a discrete intent label: `{forward, backward, stop}`. The model operated on a short temporal window of synchronized sensor readings and learned the signal signature of each intent class across all three modalities simultaneously.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/motion_prediction_validation.mp4" type="video/mp4">
</video>
*Intent estimation validation where the robot pauses, classifies intent from onboard sensor streams, and executes the corresponding action.*

The validation result was strong: the classifier correctly identified direction intent with high reliability, and the dog successfully stopped, waited for a classification, and moved in the correct direction.

**Refinement - gripper wrist position as intent signal:**  
Initial attempts used arm twist, wrist rotation, as the primary intent signal, but this showed high loss rates because the D1 wrist joint has low torque capacity and did not deflect reliably under human force. We switched to **gripper wrist position** as the primary intent feature, which produced a much cleaner signal.

**Carry mode logic:**  
Once an object is lifted, the arm's base and wrist motors are switched into a **compliant mode**, reducing active torque so the human can physically move the shared load without fighting the controller. In this mode:

- Small encoder displacements below a threshold `theta_min` -> **arm IK compensation only** so the arm accommodates the motion without commanding the legs
- Large encoder displacements above `theta_max` -> **locomotion command issued** and the intent-classifier output triggers the RL policy to step in the inferred direction

This threshold-based hybrid created a natural compliance band: the robot absorbed small perturbations gracefully and only took steps when the human's intent was clear and sustained.

---

### Milestone 9 - Full Control Stack Integration (ROS 2)
*April 2026*

All components were integrated into a unified **ROS 2 Humble** control stack running on the Go2 onboard Jetson compute:

```text
/intent_estimator       <- CNN classifier, publishes {forward, backward, stop}
/body_coordinator       <- Threshold logic, routes to leg policy or arm IK
/rl_locomotion          <- Deployed PPO policy at 50 Hz
/arm_command            <- Pinocchio/CasADi IK -> Unitree D1 SDK publisher
/state_estimator        <- InEKF fusing IMU + joint encoders + foot contact
/arm_feedback_parser    <- Parses /armFeedback, feeds intent estimator
/standup_init           <- SDK stand command -> policy handoff sequence
```

A **Streamlit telemetry dashboard** ran alongside the stack, providing real-time visualization of robot state, controller mode, intent-classifier output, and IK solver status. A **Foxglove bridge** was included for full ROS 2 topic inspection and replay. The dashboard also exposed start/stop controls for the main stack and the bridge.

The **InEKF (Invariant Extended Kalman Filter) state estimator** fused IMU linear acceleration and angular velocity with joint encoder readings and binary foot-contact signals to produce a continuous body pose and velocity estimate, the same state vector consumed by the intent estimator and body coordinator.

---

## Final Demo - Cooperative Object Carrying
*May 2026*

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/walking_demo.mp4" type="video/mp4">
</video>
*Full cooperative carry demo with a human and the Go2 jointly carrying an oversized object. Intent is estimated from onboard sensors only.*
