---
pillar: control-robotics
order: 1
title: "HQ-PCOT: Human-Quadruped Proprioceptive Co-Transport (Unitree Go2) — RL Locomotion, Pink IK & Onboard Intent Estimation"
permalink: /projects/go2-quadruped/
excerpt: "A three-layer ROS 2 Humble co-transport stack on a Unitree Go2 + D1 arm: PPO locomotion trained in MJLab, Pink differential-IK arm control, and GRU intent classifiers (500 ms @ 200 Hz, exported to ONNX) that read human intent from proprioception alone — no motion capture, no force/torque sensor. Validated with leave-one-bag-out cross-validation and benchmarked against voice and teleoperation baselines. 6-person MEng capstone."
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

**Project:** HQ-PCOT — *Human-Quadruped Proprioceptive Co-Transport via Hierarchical Control*  
**Timeframe:** Sep 2025 – May 2026  
**Affiliation:** UC Berkeley — Master of Engineering capstone, Mechanical Engineering  
**Team:** 6 members -> 2 sub-teams (RL / MPC) -> merged into unified control stack  
**Tools:** ROS 2 Humble, Docker, Python + C++, MuJoCo, MJLab, PPO, Pink / Pinocchio, PyTorch, ONNX Runtime, Unitree SDK, Streamlit, Foxglove  
**Robot:** Unitree Go2 quadruped (Jetson Orin onboard compute) + Unitree D1 arm (6-DOF + gripper)

---

## Project Overview

This capstone began as an open-ended exploration: take a Unitree Go2 quadruped robot, implement intelligent locomotion control, and, if time allowed, tackle the robotic arm attached to its back. What started as a parallel experiment between two control philosophies, RL vs. MPC, evolved into **HQ-PCOT** — a unified, three-layer cooperative control system capable of carrying an oversized object alongside a human, using **no external sensors or motion capture** and relying only on the robot's onboard IMU, foot force sensors, joint encoders, and arm feedback.

The name states the thesis: co-transport driven by **proprioception**. The robot never sees its human partner. It infers what they intend to do next purely from the forces and deflections that the shared object transmits into its own body and arm.

The later-stage system expanded beyond simple forward/backward intention decoding. After the initial cooperative carrying result, the interaction pipeline was extended to classify sideways transport intent and arm up/down motion as well, making the robot substantially more useful in a realistic shared-carry task with obstacle avoidance and path correction.

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

<video width="100%" controls preload="none" poster="/assets/images/projects/Go2/isaace_lab_forward_walk-poster.jpg">
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

<video width="100%" controls preload="none" poster="/assets/images/projects/Go2/First_Hardware_deployment-poster.jpg">
  <source src="/assets/images/projects/Go2/First_Hardware_deployment.mp4" type="video/mp4">
</video>

<video width="100%" controls preload="none" poster="/assets/images/projects/Go2/walk_these_ways_stand-poster.jpg">
  <source src="/assets/images/projects/Go2/walk_these_ways_stand.mp4" type="video/mp4">
</video>
*First hardware deployment showing static hopping and poor stability during turning and lateral gait transitions.*

**Response:** We spent roughly one week re-reading the Unitree SDK documentation and community forums. The fix for the frequency issue required explicitly **disabling the MCF service and Sports Mode service** before policy deployment. These services had to be fully stopped, not merely paused, in order to release motor-controller bandwidth. We also began hyperparameter tuning and relaunched training for **20,000 episodes**.

---

### Milestone 3 - Retraining & Partial Improvement
*November-December 2025*

The 20,000-episode retrain with tuned hyperparameters showed measurable but limited improvement. Turning stability improved noticeably, and the runtime body-height command became more responsive. However, the characteristic jumping gait, short, bouncy steps instead of fluid walking, persisted.

<video width="100%" controls preload="none" poster="/assets/images/projects/Go2/walk_these_ways-poster.jpg">
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

<video width="100%" controls preload="none" poster="/assets/images/projects/Go2/mpc_deploy-poster.jpg">
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

| Layer | Package | Method | Role |
|---|---|---|---|
| **High** | `intent_estimator` | GRU sequence classifiers served through ONNX Runtime — one node each for front/back, left/right, up/down | Predicts human intended motion from proprioceptive streams |
| **Mid** | `coordination_module` | Threshold-based arbitration (`intent_command_coordinator`, plus a `teleop_coordinator` for the baseline) | Decides whether to step, compensate with the arm only, or both |
| **Low** | `locomotion_controller` + `arm_pink_controller` | PPO policy at 50 Hz; Pink differential IK on a Pinocchio model | Executes leg gaits and arm joint targets |

Supporting packages complete the stack: `go2_state_converter` (Go2 lowstate + D1 servo feedback → `/imu`, `/joint_states`, TF), `icon_lab_d1_ros2` (ROS/UDP bridge to the D1 servos), `hq_pcot_msgs` (shared message definitions), `hq_pcot` (launch), and `telemetry_dashboard`.

The three sub-tasks, motion training, arm control, and full-stack integration, were divided among the team.

---

### Milestone 6 - Arm Control: SDK -> MuJoCo DLS IK -> Pink Differential IK
*January-February 2026*

The D1 robotic arm (6-DOF + gripper) required building an inverse-kinematics pipeline from scratch because the Unitree SDK only exposes low-level joint angle commands.

**Stage 1: SDK familiarization**  
We tested the official Unitree D1 SDK, including forward kinematics, multi-joint angle publishing, and driving modes. This established the baseline communication layer: the host machine connects to the arm via Ethernet, publishes joint-angle targets and a driving-mode flag (mode `0` for position control), and reads back joint states.

**Stage 2: MuJoCo Damped Least Squares IK**  
We implemented an IK solver using MuJoCo's internal Jacobian computation (`mj_jacSite`). The solver uses **Damped Least Squares (DLS)**, a regularized pseudoinverse method that avoids singularity-induced instability:

```text
Delta theta = J^T (J J^T + lambda^2 I)^-1 Delta x
```

where `lambda` is the damping factor, `J` is the `6 x n` site Jacobian, and `Delta x` is the Cartesian error. The pipeline accepted XYZ Cartesian input, computed joint deltas, published them through the SDK, and read back encoder feedback.

<video width="100%" controls preload="none" poster="/assets/images/projects/Go2/arm_ik-poster.jpg">
  <source src="/assets/images/projects/Go2/arm_ik.mp4" type="video/mp4">
</video>
*MuJoCo DLS IK solver enabling Cartesian XYZ control over the Unitree D1 arm.*

**Stage 3: Pink differential IK on a Pinocchio model (final)**  
The MuJoCo solver had two limitations: it carried no notion of joint limits or task priority, and it tied the arm to a host machine over Ethernet. The final controller (`arm_pink_controller`) moved to **Pink**, a task-space differential-IK library built on **Pinocchio**. Instead of solving one damped pseudoinverse, Pink assembles a small **weighted quadratic program each control tick**: tasks (end-effector pose, posture regularization) become weighted objectives, and joint position/velocity limits enter as hard inequality constraints, so the solution is feasible by construction rather than clipped after the fact.

That reframing bought three things the DLS solver could not give:

- **Orientation as a weighted task.** Keeping the gripper level while carrying is expressed as an orientation task with its own weight, traded off smoothly against the position task instead of fighting it as a hard equality.
- **Joint limits respected in the solve.** Limits are constraints in the QP, which removed the limit-clipping discontinuities that made the DLS output jerk near the edge of the workspace.
- **Posture regularization.** A low-weight posture task resolves the arm's redundancy toward a neutral carry pose, which keeps the elbow from drifting into awkward configurations over a long transport run.

Two nodes run in the final stack: `d1_arm_controller` for general pose control, and `d1_pink_z_ref_controller`, a dedicated **vertical-reference controller** that holds or shifts the carried object's height — the actuation counterpart to the up/down intent classifier. Both publish loop-health telemetry and wait on fresh `/arm/servo_feedback` before commanding, so a stale feedback link stalls the controller instead of driving the arm open-loop.

Commands reach the servos through `icon_lab_d1_ros2`, a **ROS/UDP bridge** that carries D1 servo feedback and commands. Routing the arm through a ROS 2 node on the Jetson removed the Ethernet-to-host dependency entirely — the whole stack runs onboard.

The D1 has **6 active DOF plus 1 gripper**, with the gripper driven separately by a binary open/close command.

---

### Milestone 7 - Locomotion Retraining: Isaac Gym -> MJLab, Imitation Learning
*February-March 2026*

With the unified goal defined, the locomotion policy needed to be rebuilt to support stable standing, smooth walking without the hopping artifact, and, critically, walking with the D1 arm mounted and potentially loaded.

**MJLab conversion (20x speedup):**  
We ported the Walk These Ways training stack from Isaac Gym to **MJLab** — MuJoCo-based training — and stripped out components irrelevant to our use case, such as gait switching, special actions, and curriculum scheduling. Keeping training and the arm-augmented model in the same physics engine also removed a source of sim-to-sim mismatch. Training speed improved by more than **20x**, reducing iteration cycles from hours to minutes.

**Reward shaping additions:**

| Addition | Purpose |
|---|---|
| Minimum body height penalty | Prevents crouching and collapse |
| Foot contact reward | Encourages correct trot contact pattern |
| IMU tilt penalty | Penalizes excessive body roll and pitch |
| IMU acceleration constraint | Smooths velocity transitions and eliminates hopping |
| Domain randomization (external force) | Random pushes during training for disturbance robustness |
| Standing reward | Explicit reward for stable static stance |

<video width="100%" controls preload="none" poster="/assets/images/projects/Go2/mj_lab_train-poster.jpg">
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

### Milestone 8 - Human Intent Estimation: First Classifier on Proprioceptive Streams
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

<video width="100%" controls preload="none" poster="/assets/images/projects/Go2/motion_prediction_validation-poster.jpg">
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

All components were integrated into a unified **ROS 2 Humble** workspace running on the Go2's **Jetson Orin**, packaged as a **Docker image** so the entire stack — ROS, ONNX Runtime, Pinocchio/Pink, and the Unitree SDK — rebuilds identically on the robot instead of depending on a hand-configured Jetson:

```text
intent_estimator       front_back / left_right / up_down GRU nodes (ONNX Runtime)
coordination_module    intent_command_coordinator (autonomous) | teleop_coordinator (baseline)
locomotion_controller  policy_controller (PPO @ 50 Hz) + standup_init handoff
arm_pink_controller    d1_arm_controller + d1_pink_z_ref_controller (Pink IK)
icon_lab_d1_ros2       ROS/UDP bridge for D1 servo feedback and commands
go2_state_converter    Go2 lowstate + D1 servo feedback -> /imu, /joint_states, TF
hq_pcot_msgs           shared message definitions (incl. LoopStatus)
telemetry_dashboard    Streamlit UI, launches the stack
```

State handling is deliberately lightweight: `go2_state_converter` republishes the Go2's own `lowstate` and the D1 servo feedback into standard ROS interfaces (`/imu`, `/joint_states`, and the robot TF tree). Because every layer of HQ-PCOT consumes proprioception directly, the stack never needed a global pose estimate — which is precisely why it can run with no motion capture.

**Real-time health monitoring.** Every node publishes a custom `hq_pcot_msgs/LoopStatus` message on a `/status/...` topic carrying not just a state code but **loop timing**: `avg_loop_ms`, `p99_loop_ms`, `max_loop_ms`, `budget_ms`, `deadline_miss_count`, and `sample_count`. Tracking p99 latency and explicit deadline misses against a declared budget — rather than average rate alone — came directly from the 50 Hz lesson earlier in the project: on this robot, control problems announce themselves as timing problems first. Nodes also expose *why* they are idle (`waiting for fresh /lowstate`, `waiting for /arm/servo_feedback`, `waiting for standing_init readiness`), which turns a silent robot into a diagnosable one.

A **Streamlit telemetry dashboard** (`localhost:8501`) visualizes robot state, controller mode, intent output, and each node's loop health, and can start the control stack and a **Foxglove bridge** (port `8765`) for full topic inspection and replay.

---

### Milestone 10 - Expanded Intention Dataset, Preprocessing & GRU Classifiers
*April 2026*

Once the initial forward/backward classifier and carry logic were working reliably, the next limitation became obvious: cooperative transport is not only about moving forward or stopping. A practical shared-carry system also needs to understand lateral correction and vertical object adjustment. To address that, the data-collection pipeline was extended so the team could capture new interaction examples for **side walking** and **arm up/down** commands while the robot was holding a shared object.

Data was recorded straight off the robot as **ROS 2 bags** while a human partner deliberately induced lateral carry motion and vertical load adjustment. A parser converted each bag into windowed `X/y/t/seg` arrays, and the model moved from single-frame classification to a **GRU sequence model** — the decisive change, because human intent lives in the *dynamics* of a push, not in any instantaneous sensor value.

**Window and sampling.** Every training sample is a **500 ms history window sampled at 200 Hz — 100 timesteps**. Long enough to contain the signature of a deliberate push; short enough that the robot still reacts promptly.

**Per-task feature sets.** The two classifiers deliberately read *different* parts of the robot, because the two intents show up in different physics:

| Task | Labels | Features | Why these signals |
|---|---|---|---|
| **Left / right** | `0,3,4` = rest / left / right | foot force, IMU acceleration, joint velocity (`ff accel dq`) | A lateral push is a whole-body event: it loads the feet asymmetrically and perturbs the base before the arm moves much |
| **Up / down** | `0,5,6` = rest / up / down | arm joint angles, arm servo currents (`arm_angles arm_currents`) | A vertical adjustment is felt in the arm: the servos must fight the load change, so the current draw reports it before the pose visibly changes |

Using **servo current** as an intent signal is what let the system sense vertical force without any force/torque sensor — the motors are the load cell.

**Label hygiene.** Two preprocessing rules did most of the work of making the "rest" class honest:

- **Boundary exclusion (`e060`)** — rest samples within **0.60 s** of an action segment are dropped, so the model is not trained on ambiguous wind-up frames where the human has begun moving but the label still reads rest.
- **Pure-history filtering (`hpure`)** — a window is kept only if its *entire* 500 ms history sits inside one contiguous label segment. Without this, windows straddling a transition carry two intents and teach the model contradictions.

**Evaluation: leave-one-bag-out.** Accuracy on a random split would be self-deceiving here, because consecutive windows from one recording overlap heavily — a random split leaks nearly identical frames across train and test. Instead the models were validated with **leave-one-bag-out (LOBO) cross-validation**, retraining once per held-out bag so every evaluation is against an interaction session the model has never seen. Selection used **`avg_macro_f1`, `min_macro_f1`, and `min_worst_class_f1`** rather than accuracy — deliberately including worst-case metrics, since a classifier that is excellent on average but fails on one direction is unsafe on hardware. A **1D CNN** was trained as a baseline under the identical pipeline; the GRU won on these metrics and became the deployed model for both tasks.

**Deployment.** Trained models export to **ONNX** alongside a `.deploy.yaml` manifest that pins everything inference needs to stay consistent with training — `input_layout: NCT`, `num_timesteps: 100`, `window_ms: 500`, `sampling_hz: 200`, the label set, the selected feature blocks, and the **normalization statistics**. That manifest is what prevents the classic deployment bug where the robot normalizes its live sensor stream differently from the training set. On the robot, `intent_estimator` loads the ONNX graphs through **ONNX Runtime** on the Jetson and predicts by **argmax** with no extra confidence threshold.

<video src="/assets/images/projects/Go2/side-walk.mp4" autoplay loop muted playsinline width="100%" aria-label="Side-Walk Classifier Demo"></video>
*GRU-based side-walk intent classifier integrated into the cooperative transport pipeline.*

<video src="/assets/images/projects/Go2/arm-up-down.mp4" autoplay loop muted playsinline width="100%" aria-label="Up-and-Down Classifier Demo"></video>
*Vertical up/down interaction classifier for shared load adjustment during transport.*

---

## Final Demo - Cooperative Object Transport with Obstacle Avoidance
*May 2026*

With the expanded classifiers integrated, the final system moved from a proof-of-concept carrying demo to a more complete **physical cooperative transport** task. The robot and a human partner jointly transported an object while negotiating the environment and avoiding obstacles, with the Go2 continuously interpreting intent from onboard sensing alone and blending locomotion, arm compliance, and trajectory adjustment in real time. This was a more demanding benchmark than the earlier demos because it required the control stack to remain stable while interpreting multiple classes of interaction intent and executing them under load.

<video width="100%" controls preload="none" poster="/assets/images/projects/Go2/HQ-PCoT_2-poster.jpg">
  <source src="/assets/images/projects/Go2/HQ-PCoT_2.mp4" type="video/mp4">
</video>
*Integrated physical cooperative transport demo with obstacle avoidance and multi-class intent understanding.*

The integrated system performed strongly in evaluation. Across **six rounds per method**, the cooperative transport stack outperformed both **voice control** and **pure human teleoperation** baselines. The comparison is a fair one because the teleoperation baseline runs through the same stack — `coordination_module` ships a `teleop_coordinator` alongside the autonomous `intent_command_coordinator`, so both conditions share identical locomotion, arm control, and hardware paths, and only the intent source changes.

That result mattered because it suggested the shared-autonomy layer was doing more than simply replacing one manual interface with another. It was helping the robot respond faster and more naturally to physical human intent than command-mediated control strategies.

![Evaluation Result](/assets/images/projects/Go2/evaluation.png)
*Comparison of the integrated cooperative transport system against voice control and direct human teleoperation.*

<video width="100%" controls preload="none" poster="/assets/images/projects/Go2/walking_demo-poster.jpg">
  <source src="/assets/images/projects/Go2/walking_demo.mp4" type="video/mp4">
</video>
*Earlier cooperative carry demo showing the core onboard-sensing transport behavior before the expanded classifier stage.*

The next step for the project is to push beyond reactive shared transport and move toward **proactive cooperative transport**, where the robot does not simply respond to force cues and classified intent after they occur, but begins predicting partner behavior and assisting more intelligently before large corrections are needed.

---

## Repositories

- **[HQ-PCOT control stack](https://github.com/elijah-waichong-chan/hq-pcot)** — the ROS 2 Humble workspace deployed on the Go2's Jetson Orin: intent estimation, coordination, locomotion, and Pink-based arm control, packaged with Docker.
- **[Human Intent Estimator](https://github.com/jabichebli/human-intent-estimator)** — the training pipeline: ROS 2 bag parsing, windowed dataset construction, GRU/CNN training, leave-one-bag-out evaluation, and ONNX export.
