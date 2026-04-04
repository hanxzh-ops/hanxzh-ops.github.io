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
**Team:** 6 members → 2 sub-teams (RL / MPC) → merged into unified control stack  
**Tools:** Python, C++, MuJoCo, Isaac Lab, Pinocchio, CasADi, ROS 2 Humble, Unitree SDK, PPO, Streamlit  
**Robot:** Unitree Go2 quadruped + Unitree D1 robotic arm (6-DOF + gripper)

---

## Project Overview

This capstone began as an open-ended exploration: take a Unitree Go2 quadruped robot, implement intelligent locomotion control, and — time permitting — tackle the robotic arm attached to its back. What started as a parallel experiment between two control philosophies (RL vs. MPC) evolved into a unified, three-layer cooperative control system capable of carrying an oversized object alongside a human, using **no external sensors or motion capture** — only the robot's onboard IMU, foot force sensors, joint encoders, and arm feedback.

The final demo shows the Go2 walking in coordination with a human to carry a shared object, with intent estimated purely from the physical signals of the interaction itself.

---

## Annotated Timeline

---

### 🔵 Milestone 1 — Scoping & Team Split
*September 2025*

The team began by defining the first concrete objective: **stable locomotion control** on the Go2. Rather than committing to a single method, we split into two parallel sub-teams to explore the two dominant paradigms in legged robot control:

- **RL Team** — train a neural network policy end-to-end in simulation using Proximal Policy Optimization (PPO), then deploy via sim-to-real transfer.
- **MPC Team** — implement a convex Model Predictive Controller based on the MIT Cheetah 3 work (Di Carlo et al., IROS 2018), which formulates locomotion as a real-time constrained quadratic program over a receding horizon.

The rationale: both approaches had published results on similar hardware, but their real-world performance on the Go2 under our constraints (no motion capture, no external state estimation hardware) was an open question.

---

### 🔵 Milestone 2 — RL Training: Walk These Ways on Isaac Lab
*October 2025*

The RL team adopted [Walk These Ways GO2](https://github.com/Teddy-Liao/walk-these-ways-go2) as the training backbone. This repository implements a PPO-based locomotion policy trained in **Isaac Gym**, with a parameterized command interface that allows runtime control of gait style, speed, and body height.

**Training setup:**
- Environment: Isaac Gym (GPU-accelerated parallel simulation, ~4096 environments simultaneously)
- Policy: PPO with a Multi-Layer Perceptron actor-critic
- Observation space: proprioceptive only — joint positions/velocities, IMU orientation, previous actions, command input
- Action space: target joint position offsets at 50 Hz
- Initial training run: **10,000 episodes** on the lab server

The simulation result looked promising in the Isaac Gym visualizer — the dog walked forward stably in a variety of gaits and responded to velocity commands.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/isaace_lab_forward_walk.mp4" type="video/mp4">
</video>
*Isaac Lab forward walking policy — 10,000 episode training run.*

---

### 🔴 Pivot 1 — First Real Deployment: Communication & Stability Issues
*November 2025*

Deploying the trained policy to the physical Go2 revealed two immediate problems.

**Problem 1: LCM communication channel conflicts.**  
The Unitree Go2 runs internal services (MCF service, Sports Mode service) that continuously send control commands to the motor controllers. During our first deployment attempts, these services were left running — they competed with our policy's commands for bandwidth and caused both controllers to simultaneously attempt corrections, resulting in erratic, oscillating behavior.

**Problem 2: Effective control frequency dropped to ~5 Hz.**  
Despite training at 50 Hz, the deployed policy was only executing at approximately 5 Hz due to the bandwidth contention above. This 10× frequency mismatch between training and deployment is a known sim-to-real failure mode — the policy's internal timing assumptions were violated entirely.

**Problem 3: Standing instability.**  
The dog had significant difficulty transitioning to a stable stand from rest. We had to issue an internal SDK stand command first, then hand off to the policy. Once standing, the policy caused continuous small hops in the static position and became unstable during turning and lateral (crab) walking.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/First_Hardware_deployment.mp4" type="video/mp4">
</video>
<video width="100%" controls>
  <source src="/assets/images/projects/Go2/walk_these_ways_stand.mp4" type="video/mp4">
</video>
*First hardware deployment — hopping in static position, instability on turning and lateral gait.*

**Response:** We spent approximately one week re-reading the Unitree SDK documentation and community forums. The fix for the frequency issue required explicitly **disabling the MCF service and Sports Mode service** before policy deployment — these services must be fully stopped, not just paused, to release motor controller bandwidth. We also began hyperparameter tuning and relaunched training for **20,000 episodes**.

---

### 🔵 Milestone 3 — Retraining & Partial Improvement
*November–December 2025*

The 20,000-episode retrain with tuned hyperparameters showed measurable but limited improvement. Turning stability improved noticeably, and the runtime body height command became more responsive. However, the characteristic "jumping" gait — short, bouncy steps rather than fluid walking — persisted.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/walk_these_ways.mp4" type="video/mp4">
</video>
*20,000-episode retrained policy — improved turning, adjustable height, but hopping gait persists.*

---

### 🔴 Pivot 2 — Root Cause Found: 50 Hz Fix Changes Everything
*December 2025*

After disabling the MCF and Sports Mode services and confirming 50 Hz policy execution, the locomotion quality improved dramatically. The dog walked with a smooth, stable trot, held its heading during turning, and responded to lateral commands without oscillation. This was the single most impactful fix of the entire RL development phase — not more training data, not architecture changes, but correctly configuring the deployment environment to match the training assumptions.

**Key lesson:** Sim-to-real failure is often not a policy problem — it is an integration problem. Validating the full deployment pipeline (frequency, communication, service conflicts) should happen before any hyperparameter tuning.

---

### 🔴 Pivot 3 — MPC Team: Real-Time Solver Divergence on Hardware
*December 2025*

In parallel, the MPC sub-team implemented a convex MPC locomotion controller based on the MIT Cheetah 3 formulation (Di Carlo et al., IROS 2018). The controller models the robot as a single rigid body, linearizes the equations of motion, and solves a quadratic program (QP) at each control step using **IPOPT** to compute optimal ground reaction forces, which are then mapped to joint torques via the Jacobian transpose.

In MuJoCo simulation, the controller produced clean, stable gaits with good disturbance rejection.

On real hardware, the controller failed to converge reliably. The Go2's onboard compute introduced **variable time delays** in the control loop — delays that were small enough to be negligible in simulation but large enough to cause the IPOPT solver to receive inconsistent state observations between iterations. The result was solver divergence: the QP solution would "explode" to physically unrealistic ground reaction forces, causing the robot to violently destabilize.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/mpc_deploy.mp4" type="video/mp4">
</video>
*MPC real deployment — IPOPT solver divergence due to hardware timing delays.*

This is a known challenge with real-time MPC on legged robots: the solver must complete within a strict time budget, and any jitter in state feedback breaks the warm-start assumptions that make receding-horizon solvers tractable. Mitigations (solver warm-starting, reduced horizon length, state prediction to compensate for delay) were explored but did not fully resolve the issue within the project timeline.

---

### 🔵 Milestone 4 — Teams Merge: New Unified Goal
*January 2026*

With both sub-teams having hit deployment walls, we reconverged and redefined the project's scope around a more ambitious and unified objective:

> **Develop a cooperative human-robot object carrying system — using only the robot's onboard sensors — where a human and the Go2 (with D1 arm attached) jointly carry an oversized object, with the robot autonomously inferring human intent and coordinating its body and arm accordingly.**

![Concept overview](/assets/images/projects/Go2/concept1.jpg)
*Unified project concept — cooperative object carrying with no external sensors or teleoperation.*

The key design constraint that shaped everything: **no external devices**. No motion capture, no force/torque sensors mounted to the object, no handheld remote. The robot must infer what the human wants to do purely from signals already available on the hardware — foot force sensors, IMU, and arm joint encoders.

This constraint is what separates our approach from most published cooperative manipulation work, which relies on wrist-mounted F/T sensors or external tracking.

---

### 🔵 Milestone 5 — Three-Layer Control Architecture
*January 2026*

To structure the problem, we designed a **three-layer hierarchical control pipeline**:

![Control pipeline architecture](/assets/images/projects/Go2/Control pipeline.jpg)
*Three-layer control pipeline — intent estimation → body coordination → low-level execution.*

| Layer | Name | Method | Role |
|---|---|---|---|
| **High** | Human Intent Estimator | CNN classifier on sensor streams | Predicts human's intended motion direction from foot force, IMU, and arm encoder signals |
| **Mid** | Body Coordination Optimizer | Threshold-based hybrid controller | Decides whether to move legs, compensate with arm IK only, or both |
| **Low** | Execution Layer | RL locomotion policy + constrained IK solver | Executes leg gaits and arm joint targets |

The three sub-tasks — motion training, arm control, and control stack integration — were divided among the team.

---

### 🔵 Milestone 6 — Arm Control: SDK → MuJoCo IK → Pinocchio + CasADi
*January–February 2026*

The D1 robotic arm (6-DOF + gripper) required building a full inverse kinematics pipeline from scratch, since the Unitree SDK only exposes low-level joint angle commands.

**Stage 1: SDK familiarization**  
We tested the official Unitree D1 SDK — forward kinematics, multi-joint angle publishing, and different driving modes. This established the baseline communication layer: our host machine connects to the arm via Ethernet, publishes joint angle targets and a driving mode flag (mode `0` = position control), and reads back joint states.

**Stage 2: MuJoCo Damped Least Squares IK**  
We implemented an IK solver using MuJoCo's internal Jacobian computation (`mj_jacSite`). The solver uses **Damped Least Squares (DLS)** — a regularized pseudoinverse method that avoids singularity-induced instability:

```
Δθ = Jᵀ(JJᵀ + λ²I)⁻¹ Δx
```

where `λ` is the damping factor, `J` is the 6×n site Jacobian, and `Δx` is the Cartesian error. The pipeline accepted XYZ Cartesian input, computed joint deltas, published via the SDK, and read back encoder feedback. **CycloneDDS** was used as the ROS 2 middleware bridge between the host machine and the arm.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/arm_ik.mp4" type="video/mp4">
</video>
*MuJoCo DLS IK solver — Cartesian XYZ control via Ethernet.*

**Stage 3: Pinocchio + CasADi constrained IK (final)**  
The MuJoCo solver had two limitations: no support for joint constraints, and Ethernet-only operation. We migrated to **Pinocchio** (rigid body dynamics library) for kinematics and **CasADi** for nonlinear optimization, enabling a proper constrained IK formulation:

- **Gripper orientation constraint:** The end-effector is constrained to maintain a fixed reference pose (initial horizontal orientation). This is enforced as a cost term in the CasADi objective — penalizing deviation from the reference SO(3) orientation — rather than a hard equality constraint, which improved solver convergence.
- **Partial-DOF optimization:** Since the arm only needs to pick objects from the side, full 6-DOF solving is unnecessary. We fixed proximal joints and optimized only the distal subset, reducing the problem dimensionality and improving solve time.
- **Wireless operation:** Removed the Ethernet dependency by routing commands through the ROS 2 `/arm_command` node over the Jetson's WiFi link.

The `/arm_command` node consolidates: Cartesian target input → Pinocchio/CasADi IK solve → joint angle array + mode flag → Unitree SDK publisher → arm execution.

The D1 has **6 active DOF + 1 gripper**. In the final solver, proximal joints (shoulder rotation, upper arm) are fixed to a side-pick configuration; the distal joints (elbow, wrist pitch, wrist roll) are optimized. The gripper joint is separately controlled via a binary open/close command.

---

### 🔵 Milestone 7 — Locomotion Retraining: Isaac Lab → MJLab, Imitation Learning
*February–March 2026*

With the unified goal defined, the locomotion policy needed to be rebuilt to support: stable standing, smooth walking without the hopping artifact, and — critically — walking with the D1 arm mounted and potentially loaded.

**MJLab conversion (20× speedup):**  
We ported the Walk These Ways training stack from Isaac Gym to **Isaac Lab** (MuJoCo-based, lighter runtime), stripping out components irrelevant to our use case (gait switching, special actions, curriculum scheduling). Training speed improved by more than **20×**, reducing iteration cycles from hours to minutes.

**Reward shaping additions:**

| Addition | Purpose |
|---|---|
| Minimum body height penalty | Prevents crouching / collapse |
| Foot contact reward | Encourages correct trot contact pattern |
| IMU tilt penalty | Penalizes excessive body roll/pitch |
| IMU acceleration constraint | Smooths velocity transitions, eliminates hopping |
| Domain randomization (external force) | Random pushes applied during training for disturbance robustness |
| Standing reward | Explicit reward for stable static stance |

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/mj_lab_train.mp4" type="video/mp4">
</video>
*MJLab training run — smooth trot gait, no hopping, stable standing.*

**Imitation learning for arm-loaded walking:**  
The mounted D1 arm adds significant mass and shifts the center of mass. A policy trained on the bare Go2 model cannot generalize to this configuration without retraining.

We modified the MuJoCo XML to include the arm's geometry, mass distribution, and joint constraints — measured physically and referenced against the D1 datasheet.

![D1 arm dimensions and mass properties](/assets/images/projects/Go2/arm dimensions.jpg)
*D1 arm physical dimensions and mass properties added to MuJoCo XML for imitation learning.*

Training curriculum:
1. **Base policy transfer** — initialize from the trained bare-Go2 policy.
2. **Fixed arm fine-tuning** — arm held in folded position; policy learns to compensate for added mass.
3. **Random fixed arm positions** — arm placed at a random fixed joint configuration at episode start; policy learns to walk stably across the arm's configuration space.
4. **Dynamic arm randomization** — arm position randomized every 5 seconds within an episode, simulating the arm moving during a carry task. Policy must maintain gait stability under dynamic CoM shifts.

![Go2 with D1 arm mounted](/assets/images/projects/Go2/dog_with_arm.jpg)
*Go2 with D1 arm deployed — policy trained to handle dynamic arm configuration changes.*

---

### 🔵 Milestone 8 — Human Intent Estimation: Sensor Fusion + CNN Classifier
*March–April 2026*

The core research contribution of this project: **inferring human locomotion intent from physical interaction signals, using only onboard sensors.**

**Sensor modalities used:**
- **Foot force sensors** — contact force distribution shifts when a human applies force to a shared object
- **IMU (linear acceleration + angular rate)** — body perturbation from external forces
- **Arm joint encoders** (`/armFeedback` topic) — micro-deflections in encoder readings when force is applied to the arm or a held object, even without active motion

**Validation experiment:**  
The arm was held at a fixed position gripping a rigid stick. A team member pushed the stick forward or backward while we logged all three sensor streams simultaneously. Multiple labeled data bags were collected for "push forward," "push backward," and "no input" classes.

![Data collection setup](/assets/images/projects/Go2/data collection.jpg)
*Sensor data collection — fixed arm holding stick, human applies directional force.*

A small **1D CNN classifier** was trained on windowed sensor streams to output a discrete intent label: `{forward, backward, stop}`. The model operates on a short temporal window of synchronized sensor readings, learning to detect the characteristic signal pattern of each intent class across all three modalities simultaneously.

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/motion_prediction_validation.mp4" type="video/mp4">
</video>
*Intent estimation validation — dog stops, classifies intent from sensor stream, executes corresponding action.*

The validation result was strong: the classifier correctly identified direction intent with high reliability, and the dog successfully stopped, waited for a classification, and moved in the correct direction.

**Refinement — gripper wrist position as intent signal:**  
Initial attempts used arm twist (wrist rotation) as the primary intent signal, but this showed high loss rates — the D1's wrist joint has low torque capacity and was not reliably deflecting under human force. We switched to **gripper wrist position** (the linear position of the wrist joint encoder) as the primary intent feature, which gave a much cleaner signal.

**Carry mode logic:**  
Once an object is lifted, the arm's base and wrist motors are set to a **compliant (loose) mode** — reducing active torque so the human can physically move the shared load without fighting the controller. In this mode:

- Small encoder displacements (below a threshold θ_min) → **arm IK compensation only** — the arm moves to accommodate the human's motion without commanding the legs
- Large encoder displacements (above threshold θ_max) → **locomotion command issued** — the intent classifier output triggers the RL policy to step in the inferred direction

This threshold-based hybrid creates a natural compliance band: the robot absorbs small perturbations gracefully and only takes steps when the human's intent is clear and sustained.

---

### 🔵 Milestone 9 — Full Control Stack Integration (ROS 2)
*April 2026*

All components were integrated into a unified **ROS 2 Humble** control stack running on the Go2's onboard Jetson compute:

```
/intent_estimator       ← CNN classifier, publishes {forward, backward, stop}
/body_coordinator       ← Threshold logic, routes to leg policy or arm IK
/rl_locomotion          ← Deployed PPO policy at 50 Hz
/arm_command            ← Pinocchio/CasADi IK → Unitree D1 SDK publisher
/state_estimator        ← InEKF fusing IMU + joint encoders + foot contact
/arm_feedback_parser    ← Parses /armFeedback, feeds intent estimator
/standup_init           ← SDK stand command → policy handoff sequence
```

A **Streamlit telemetry dashboard** runs alongside the stack, providing real-time visualization of robot state, controller mode, intent classifier output, and IK solver status. A **Foxglove bridge** is included for full ROS 2 topic inspection and replay. The dashboard exposes start/stop controls for the main stack and the bridge.

The **InEKF (Invariant Extended Kalman Filter) state estimator** fuses IMU linear acceleration and angular velocity with joint encoder readings and binary foot contact signals to produce a continuous body pose and velocity estimate — the same state vector consumed by the intent estimator and body coordinator.

---

### 🎬 Final Demo — Cooperative Object Carrying
*May 2026*

<video width="100%" controls>
  <source src="/assets/images/projects/Go2/walking_demo.mp4" type="video/mp4">
</video>
*Full cooperative carry demo — human and Go2 jointly carrying an oversized object. Intent estimated from onboard sensors only.*

**Carry sequence:**

![Carry start — approach and arm positioning](/assets/images/projects/Go2/carry_start.jpg)
*Step 1 — Arm positions to pick configuration.*

![Carry pick — gripper closes on object](/assets/images/projects/Go2/carry_pick.jpg)
*Step 2 — Gripper closes, object acquired.*

![Carry lift — object lifted, arm transitions to carry pose](/assets/images/projects/Go2/carry_lift.jpg)
*Step 3 — Object lifted, wrist and base motors set to compliant mode.*

![Carry drop — object placed at destination](/assets/images/projects/Go2/carry_drop.jpg)
*Step 4 — Human intent to stop detected, object placed.*

---

## Technical Summary

| Component | Method | Key Detail |
|---|---|---|
| RL locomotion | PPO, Isaac Lab | 20× speedup over Isaac Gym; custom reward shaping for stability |
| Sim-to-real | Proprioceptive policy + domain randomization | 50 Hz deployment; MCF/Sports Mode services must be disabled |
| MPC locomotion | Convex MPC (MIT Cheetah 3) | Works in sim; IPOPT diverges on hardware due to timing delays |
| Arm IK | Pinocchio + CasADi constrained NLP | Partial-DOF; gripper orientation cost; wireless via ROS 2 |
| Imitation learning | Curriculum: fixed → random → dynamic arm | Arm mass added to MuJoCo XML; policy robust to CoM shifts |
| Intent estimation | 1D CNN on foot force + IMU + arm encoder | No external sensors; gripper wrist position as primary feature |
| State estimation | InEKF | IMU + joint encoders + foot contact fusion |
| Control stack | ROS 2 Humble | Streamlit dashboard + Foxglove bridge; full pipeline on Jetson |

---

## What We Learned

**Deployment environment matters more than training.** The single biggest improvement to locomotion quality was not more episodes or better reward shaping — it was disabling the robot's internal services so our controller had full bandwidth at the correct frequency.

**MPC on legged robots requires careful timing architecture.** The IPOPT solver is powerful in simulation but fragile to real-world timing jitter. Future work would explore warm-started QP solvers (e.g. OSQP) with explicit delay compensation in the state predictor.

**Physical interaction is information.** The encoder deflection signal from the arm — which most controller designs would filter out as noise — turned out to be the most reliable intent signal we had. Treating compliance as a sensing modality rather than a control problem was the key insight behind the intent estimator.

**Imitation learning with domain randomization bridges the CoM shift problem.** Adding the arm mass to the simulation XML and randomizing its position during training was sufficient for the policy to generalize to real loaded-arm walking without any real-world fine-tuning.

---

## References

- Di Carlo, J., Wensing, P. M., Katz, B., Bledt, G., & Kim, S. (2018). *Dynamic Locomotion in the MIT Cheetah 3 Through Convex Model-Predictive Control.* IEEE IROS.
- Kumar, A. et al. *Walk These Ways: Tuning Robot Control for Generalization with Multiple Modular Locomotion Policies.* CoRL 2022.
- [Walk These Ways GO2 — Teddy-Liao](https://github.com/Teddy-Liao/walk-these-ways-go2)
- Hartley, R. et al. *Contact-Aided Invariant Extended Kalman Filtering for Robot State Estimation.* IJRR 2020.
