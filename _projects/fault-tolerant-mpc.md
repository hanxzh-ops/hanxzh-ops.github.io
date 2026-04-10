---
pillar: control-robotics
title: "Fault-Tolerant MPC for Aircraft Recovery (Collaborative Research)"
permalink: /projects/fault-tolerant-mpc/
excerpt: "A two-layer MPC guidance stack for rerouting a damaged aircraft toward a feasible runway or crash landing site under degraded control authority."
header:
  teaser: /assets/images/projects/MPC/cover.png
  image: /assets/images/projects/MPC/cover.png
categories:
  - Controls
tags:
  - controls
  - optimisation
  - safety
---

**Timeframe:** Sep 2025 – Dec 2025  
**Tools:** Model Predictive Control, Convex optimisation, CasADi, OSQP, Python, Simulation

## Project Overview
This project explored how a damaged aircraft could still be guided to a survivable touchdown using a guidance-level model and a fully convex optimisation pipeline. The controller was built as a two-layer stack: a long-horizon geometric planner generated a runway-aligned descent path, and a short-horizon linear time-varying MPC tracked that path while respecting input, rate, airspeed, and climb-angle limits. When the damage model reduced the aircraft's available descent authority enough to make the runway unreachable, the system switched to a crash-landing mode and replanned toward a feasible touchdown point outside restricted ground regions.

## Project Scope
- The team implemented a 6-state kinematic aircraft model with states `[x, y, h, V, chi, gamma]` and control inputs `[u_accel, u_chi_dot, u_gamma_dot]`.
- The nonlinear guidance model was linearized online at each control step and discretized with forward Euler to obtain the LTV prediction model used by MPC.
- The planning layer used a convex waypoint optimizer over a 3D approach polyline with smoothness, glide-slope, lateral-centerline, and terminal-alignment objectives.
- The tracking layer used a short-horizon MPC with explicit state, input, and input-rate constraints so the predicted motion remained dynamically reasonable under degraded authority.
- The full pipeline incorporated event-triggered replanning logic based on tracking feasibility, along-path progress, and reachable-ground-range checks.
- A crash-landing fallback mode was included so the same overall framework could retarget a touchdown region outside no-land ellipses with a stronger terminal descent penalty.

## Model & Design Specifications
The control design was intentionally lightweight so the optimisation stayed fast and robust:

- Guidance model: 3D point-mass kinematics, not a full rigid-body aircraft model.
- State vector: north position, east position, altitude, airspeed, heading angle, and climb angle.
- Control outputs: longitudinal acceleration, heading-rate command, and climb-angle-rate command.
- Simulation time step: `1 s`.
- MPC horizon: `10` steps.
- Global planner resolution: `100` base waypoints plus runway rollout points.
- Nominal speed envelope: stall `50 kt`, best glide `65 kt`, approach speed `80 kt`, never-exceed `150 kt`.
- Nominal climb-angle envelope: `-30 deg` to `+30 deg`.
- Input limits: heading-rate `+/- 5 deg/s`, climb-angle-rate `+/- 3 deg/s`, acceleration fixed at `0 m/s^2` in the current setup.
- Input slew-rate limits: `0.25 m/s^2` for acceleration, `2 deg/s` for heading-rate, and `1 deg/s` for climb-angle-rate per control step.

Those choices made the controller more of a guidance system than a low-level flight controller: the MPC generated feasible command references while an idealized inner-loop autopilot was assumed to track them.

## Pipeline
The guidance stack separated global geometry from local control:

![Guidance Pipeline](/assets/images/projects/MPC/pipeline.png)
*Two-layer guidance architecture showing the separation between long-horizon planning and short-horizon MPC tracking.*

- The planner solved a convex QP over 3D waypoints to produce a smooth approach path that converged to the runway threshold and aligned with runway heading near touchdown.
- The MPC linearized the nonlinear kinematic model at each step and tracked a short local window of the planned path using a convex QP.
- The aircraft plant was then stepped forward with the first control action, re-linearized, and the cycle repeated.

In the main test scenario, the aircraft started at `(-2000 m, -4000 m, 500 m)` with heading `170 deg`, speed `80 kt`, and a runway heading of `90 deg`. That setup forced a nontrivial turn-in and descent rather than an easy straight-in approach.

## Planner Design
The long-horizon planner optimized waypoint geometry rather than raw control inputs. The cost function combined four pieces:

- second-difference smoothness to avoid jagged waypoint paths,
- glide-slope shaping toward a `3 deg` descent profile,
- cross-track penalty to pull the path onto the runway centerline, and
- terminal alignment penalty so the final segment approached along runway heading.

The implementation also increased tracking weights closer to the runway, which made the far-field path flexible but forced the near-threshold segment to become more runway-like. After solving the base path to the threshold, the planner appended rollout points along the runway centerline so the local controller had a cleaner terminal reference.

## MPC Design
The short-horizon controller solved a convex QP over the linearized prediction model

`x_(k+1) = A_d x_k + B_d u_k`

with quadratic penalties on tracking error and control effort. The relative state cost emphasized altitude most strongly, with smaller but still meaningful penalties on lateral position, airspeed, heading, and climb angle. Additional penalties on control increments and on changes in heading/climb-angle state helped suppress aggressive or oscillatory commands.

The MPC enforced:

- airspeed bounds from stall to never-exceed speed,
- flight-path-angle bounds from the current operating envelope,
- heading-rate and climb-angle-rate limits, and
- step-to-step rate limits on all control commands.

Because the model was linearized about the current operating point at every step, the controller behaved like an LTV MPC rather than a fixed linear tracker.

## Damage Handling
Damage was modeled by tightening the aircraft's allowable climb-angle envelope in flight. In the main damage scenario, the aircraft switched from its nominal envelope to a constrained descent window, with the code applying bounds such as `gamma_max = -5 deg` or `gamma_max = -3 deg` depending on the test. That forced the aircraft into a shallower or more constrained descent and could make the original runway path infeasible.

To handle that case, the team incorporated:

- feasibility triggers based on cross-track error growth and lack of along-path progress,
- an online reachability check comparing remaining path length to maximum achievable horizontal range computed from altitude and allowed descent angle, and
- a crash-landing planner that selected a feasible touchdown region while avoiding no-land ellipses.

More specifically, the MPC tracked replan conditions using a cross-track threshold of about `100 m`, a progress-stall threshold of about `1 m` of along-path motion per step, and consecutive-step counters to prevent noise from triggering constant replanning. If the remaining runway path exceeded the reachable range under the damaged descent envelope, the controller abandoned the runway objective and switched to crash mode.

The crash-mode MPC reused the same tracking structure but added a strong terminal penalty on vertical-speed proxy near the end of the horizon to reduce impact severity at touchdown.

## Results
In simulation, the controller could guide the nominal aircraft toward the runway, detect when damage invalidated the current plan, and reconfigure the mission instead of simply failing tracking. The final system demonstrated a complete failure-management loop:

- generate a long-horizon approach path,
- track it with a constrained LTV MPC,
- monitor feasibility online,
- trigger replanning only when needed, and
- transition to an alternate touchdown objective when the runway became unreachable.

What made the project interesting technically was not just the MPC solve itself, but the pipeline integration. The planner, reachability logic, feasibility monitors, crash-site selection, and damage-aware constraints all had to work together coherently for the overall guidance architecture to behave reliably.

## Repository
- [GitHub Repository](https://github.com/hanxzh-ops/damaged-aircraft-mpc)
- [Project Report (PDF)](https://github.com/hanxzh-ops/damaged-aircraft-mpc/blob/main/docs/mpc_231a_final_report.pdf)
