---
layout: single
title: "About"
permalink: /about/
---

I'm Hanxiao Zhang — a **controls and robotics engineer** who also designs and manufactures the hardware those controllers run on. I work on the parts of robotics that have to survive contact with the real world: a policy that has to transfer from simulation to a physical robot, a Jacobian that goes singular at the worst moment, a controller that has to close the loop on a real IMU at real latency.

My core work is **robotics, controls, and simulation**. I built a full locomotion-and-manipulation stack on a Unitree Go2 quadruped — RL sim-to-real transfer fused with MPC and onboard sensing for a cooperative human-robot carrying demo that uses no external motion capture; a physics-simulated 18-DOF hexapod with analytical kinematics and a real-time tripod gait in MuJoCo; a first-principles inverse-kinematics study that benchmarked Moore-Penrose, BFGS, and Levenberg-Marquardt solvers to cut end-effector overshoot and oscillation by more than 10%; and a two-layer model-predictive guidance system that reroutes a damaged aircraft toward a survivable landing under degraded control authority. I think natively in MPC, reinforcement learning, kinematics, and sensor fusion. I also enjoy the data side — a recent study of mine compared 15 machine-learning models to predict Formula 1 race outcomes, where catching a subtle data-leakage bug mattered more than any single model.

What makes that robotics work land is that I can also **design and build the hardware**. I've run product programs end-to-end — market survey, concept selection, CAD, prototyping, and a sold-out 20-unit production run for a rotary calendar; a food-safe rotary-vane pump taken from a quantified design brief through FEA/CFD, a full GD&T tolerance package, a cast-then-machine manufacturing plan, and a leak-tested validation build; and a transformable carry-on that mechanically expands between compact and high-capacity travel modes. On the factory side I've written real automation tooling: an image-driven pipeline that converts 2D circuit schematics into Haas/Fanuc-ready G-code, and an Arduino-controlled rubber-batching system for Vibram. I think in DFM, ASME Y14.5 GD&T, BOMs, and configuration-controlled documentation, because those are what turn a clever prototype into something a shop can actually build.

That mix is the point. I can sit with a controls engineer and talk MPC and reinforcement learning, then walk to the shop floor and talk fits, finishes, and fixturing — and write the documentation that keeps both honest.

## What I work with

**Robotics & controls:** Model Predictive Control, reinforcement learning (PPO), inverse/forward kinematics, gait generation, sim-to-real, sensor fusion, MuJoCo, Isaac Lab, Pinocchio, CasADi, OSQP, ROS 2.

**Software & data:** Python, C++, OpenCV, NumPy/pandas, scikit-learn, Tkinter, convex optimization, machine learning.

**Design & manufacturing:** SolidWorks, CAD/CAM, DFM, ASME Y14.5 GD&T, tolerance stack-up, FEA & CFD, CNC milling/turning, casting, sheet metal, prototyping, metrology, BOM & ECO documentation.

## Let's talk

If you're building something that has to be designed *and* manufactured *and* made to move, that's exactly the intersection I work in. Take a look at my [projects](/projects/), grab my [resume](/resume/), or [get in touch](/contact/).
