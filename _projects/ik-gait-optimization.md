---
pillar: control-robotics
title: "Optimizing Inverse-Kinematics Convergence & Gait Patterns for a Planar Legged Robot (R² Space)"
permalink: /projects/ik-gait-optimization/
excerpt: "A first-principles MATLAB study of a 4-link planar robot — full forward/differential kinematics, a nonlinear least-squares formulation of inverse kinematics, and a benchmark of Moore-Penrose, BFGS, and Levenberg-Marquardt solvers that cut end-effector overshoot and oscillation by more than 10%."
header:
  teaser: /assets/images/projects/ik-cambridge/cover.jpg
  image: /assets/images/projects/ik-cambridge/cover.jpg
categories:
  - Controls
  - Robotics
tags:
  - robotics
  - controls
  - inverse-kinematics
  - nonlinear-optimization
  - levenberg-marquardt
  - bfgs
  - gauss-newton
  - jacobian
  - gait-generation
  - matlab
  - simulation
---

**Timeframe:** May 2024 – Jul 2024  
**Affiliation:** University of Cambridge — Bio-Inspired Robotics  
**Tools:** MATLAB, homogeneous-transform kinematics, Jacobian methods, nonlinear least-squares optimization (Moore-Penrose pseudoinverse, Gauss-Newton, Levenberg-Marquardt, BFGS), center-of-mass gait analysis

## Project Overview
This project takes a 4-link, 3-joint planar robot and rebuilds its control stack from first principles: forward kinematics from homogeneous transforms, differential kinematics through the manipulator Jacobian, and inverse kinematics posed and solved as a nonlinear least-squares optimization. On that foundation I ran a controlled benchmark of three solvers — the **Moore-Penrose pseudoinverse**, **BFGS**, and **Levenberg-Marquardt (LM)** — to determine which best resolves the end-effector to a commanded point in R² (the 2-D Cartesian plane) under increasing nonlinearity.

The central result is that introducing Levenberg-Marquardt damping in place of the baseline fixed-threshold pseudoinverse update **reduced end-effector overshoot and oscillation by more than 10%** and lowered convergence latency in the most nonlinear reaching regimes, while a parallel center-of-mass analysis of the gait isolated a single joint as the dominant, near-quadratic driver of stride length.

<figure class="align-center">
  <img src="/assets/images/projects/ik-cambridge/robot-labels.png" alt="Layout of the 4-link, 3-joint planar robot">
  <figcaption>The platform: four links (L₁–L₄) with two L-shaped terminal segments (L₅, L₆) that double as feet and end-effectors, articulated by three revolute joints (ϕ₁, ϕ₂, ϕ₃). Link lengths and masses are fixed; the joint angles are the only decision variables, making this a clean testbed for inverse kinematics and gait synthesis in R².</figcaption>
</figure>

## 1. Kinematic Model and Conventions
I model the mechanism as a serial chain of revolute joints in the plane. Let the configuration vector collect the joint angles

<div class="equation">
$$
\mathbf{q} = \begin{bmatrix} \phi_1 & \phi_2 & \cdots & \phi_n \end{bmatrix}^{\mathsf T},
$$
</div>

with fixed link lengths `L₁ … Lₙ`. Each joint `i` applies a planar rotation, represented in homogeneous coordinates by

<div class="equation">
$$
\mathbf{T}_i(\phi_i) =
\begin{bmatrix}
\cos\phi_i & -\sin\phi_i & L_i\cos\phi_i \\
\sin\phi_i & \;\;\cos\phi_i & L_i\sin\phi_i \\
0 & 0 & 1
\end{bmatrix},
$$
</div>

which simultaneously rotates the local frame by `ϕᵢ` and translates along the rotated link by `Lᵢ`. The pose of the end-effector frame relative to the base is then the ordered product of these transforms,

<div class="equation">
$$
\mathbf{T}_{0}^{\,e}(\mathbf{q}) = \prod_{i=1}^{n} \mathbf{T}_i(\phi_i),
\qquad
\begin{bmatrix} \mathbf{p}_e \\ 1 \end{bmatrix}
= \mathbf{T}_{0}^{\,e}\begin{bmatrix} \mathbf{0} \\ 1 \end{bmatrix},
$$
</div>

and the end-effector position `pₑ = (x, y)` is read from the translation column. In the simulator this product is assembled by the `HomCoord` / `rmat` routines, with one foot pinned to the ground as the kinematic root.

## 2. Forward Kinematics
Carrying out the transform product, the angles accumulate down the chain, so the Cartesian position of the end-effector is the sum of link contributions each rotated by the running total of upstream joint angles:

<div class="equation">
$$
x(\mathbf{q}) = \sum_{i=1}^{n} L_i \cos\!\Big(\sum_{k=1}^{i}\phi_k\Big),
\qquad
y(\mathbf{q}) = \sum_{i=1}^{n} L_i \sin\!\Big(\sum_{k=1}^{i}\phi_k\Big).
$$
</div>

The instructive two-link case — the canonical planar arm used to derive the method before generalizing — reduces to

<div class="equation">
$$
\begin{aligned}
x &= L_1\cos\phi_1 + L_2\cos(\phi_1+\phi_2), \\
y &= L_1\sin\phi_1 + L_2\sin(\phi_1+\phi_2).
\end{aligned}
$$
</div>

Forward kinematics is single-valued and trivial to evaluate; the difficulty — and the subject of this project — is the inverse map.

## 3. Differential Kinematics: the Manipulator Jacobian
Inverse kinematics has no closed form for a general redundant chain, so I work with the *differential* relationship between joint velocities and end-effector velocity. Differentiating the forward map with respect to time gives

<div class="equation">
$$
\dot{\mathbf{p}}_e =
\begin{bmatrix} \dot x \\ \dot y \end{bmatrix}
= \mathbf{J}(\mathbf{q})\,\dot{\mathbf{q}},
\qquad
\mathbf{J}(\mathbf{q}) = \frac{\partial \mathbf{p}_e}{\partial \mathbf{q}}
= \begin{bmatrix}
\dfrac{\partial x}{\partial \phi_1} & \cdots & \dfrac{\partial x}{\partial \phi_n} \\[6pt]
\dfrac{\partial y}{\partial \phi_1} & \cdots & \dfrac{\partial y}{\partial \phi_n}
\end{bmatrix}.
$$
</div>

For the two-link arm the partials evaluate to the closed form

<div class="equation">
$$
\mathbf{J} =
\begin{bmatrix}
-L_1\sin\phi_1 - L_2\sin(\phi_1+\phi_2) & -L_2\sin(\phi_1+\phi_2) \\
\;\;L_1\cos\phi_1 + L_2\cos(\phi_1+\phi_2) & \;\;L_2\cos(\phi_1+\phi_2)
\end{bmatrix}.
$$
</div>

Each column is the instantaneous Cartesian velocity the end-effector would acquire from a unit rate at that joint, with all others held fixed — the geometric meaning of the Jacobian. Its determinant,

<div class="equation">
$$
\det \mathbf{J} = L_1 L_2 \sin\phi_2,
$$
</div>

vanishes when `ϕ₂ → 0` or `π` (the arm fully stretched or folded). At those **kinematic singularities** the Jacobian loses rank, the end-effector cannot move instantaneously in certain directions, and any method relying on `J⁻¹` produces unbounded joint rates — the root cause of the overshoot and oscillation this project set out to suppress.

## 4. Inverse Kinematics as Root-Finding
The baseline approach treats IK as Newton-Raphson root-finding on the position error. Given a desired point `p_d` and the current pose `pₑ(q)`, define the Cartesian error `Δp = p_d − pₑ(q)`. Inverting the differential relation yields the joint correction, applied iteratively:

<div class="equation">
$$
\mathbf{q}_{k+1} = \mathbf{q}_k + \mathbf{J}^{-1}(\mathbf{q}_k)\,\big(\mathbf{p}_d - \mathbf{p}_e(\mathbf{q}_k)\big),
$$
</div>

looping until `‖Δp‖` falls below a fixed threshold. When `J` is non-square (a redundant chain, three joints driving two Cartesian coordinates) it cannot be inverted directly, so I use the **Moore-Penrose pseudoinverse**. This is the minimum-norm least-squares solution of `J Δq = Δp`; for a wide Jacobian (more joints than task dimensions) it takes the right-inverse form

<div class="equation">
$$
\mathbf{J}^{+} = \mathbf{J}^{\mathsf T}\big(\mathbf{J}\mathbf{J}^{\mathsf T}\big)^{-1},
\qquad
\Delta\mathbf{q} = \mathbf{J}^{+}\,\Delta\mathbf{p} = \arg\min_{\Delta\mathbf q} \|\Delta\mathbf q\|_2 \;\; \text{s.t. } \mathbf J\,\Delta\mathbf q = \Delta\mathbf p,
$$
</div>

implemented in MATLAB as `dx = pinv(J) * (PDes - rCurr)`. This linearizes the problem at each step and works well for small, near-linear corrections — but because the step is undamped, a large initial error or a near-singular configuration drives an aggressive update: the principal link **overshoots** the target, then the remaining joints **oscillate** through a slow corrective phase to settle. Tightening the fixed threshold only trades convergence speed for residual chatter. That structural weakness motivated reformulating IK as a damped nonlinear optimization.

## 5. Inverse Kinematics as Nonlinear Least Squares
Rather than chase a root, I minimize the squared end-effector error directly. Define the residual `e(q) = g(q) − d`, where `g(·)` is the forward-kinematics map and `d` the desired position, and the scalar cost

<div class="equation">
$$
f(\mathbf{q}) = \tfrac{1}{2}\sum_{i=1}^{m}\big(g(\mathbf{q})_i - d_i\big)^2
= \tfrac{1}{2}\,\|\mathbf{e}(\mathbf{q})\|_2^2 .
$$
</div>

Its gradient and exact Hessian are

<div class="equation">
$$
\nabla f(\mathbf{q}) = \mathbf{J}^{\mathsf T}\mathbf{e},
\qquad
\nabla^2 f(\mathbf{q}) = \mathbf{J}^{\mathsf T}\mathbf{J} + \sum_{i=1}^{m} e_i \,\nabla^2 e_i .
$$
</div>

Near a good solution the residuals `eᵢ` are small, so the second term is dropped — the **Gauss-Newton approximation** `∇²f ≈ JᵀJ`. Setting the linearized gradient to zero gives the Gauss-Newton step

<div class="equation">
$$
\Delta\mathbf{q}_{\text{GN}} = -\big(\mathbf{J}^{\mathsf T}\mathbf{J}\big)^{-1}\mathbf{J}^{\mathsf T}\mathbf{e}.
$$
</div>

This is fast and quadratically convergent near the target, but `JᵀJ` inherits the same singularity as `J`: when the arm approaches a stretched or folded pose, `JᵀJ` becomes ill-conditioned and the step blows up. The three solvers I compared are three different answers to that conditioning problem.

### 5.1 Levenberg-Marquardt
LM regularizes the Gauss-Newton normal equations with a damping term `λ ≥ 0`, interpolating between Gauss-Newton and gradient descent:

<div class="equation">
$$
\mathbf{q}_{k+1} = \mathbf{q}_k - \big(\mathbf{J}^{\mathsf T}\mathbf{J} + \lambda \mathbf{I}\big)^{-1}\mathbf{J}^{\mathsf T}\mathbf{e}.
$$
</div>

The behaviour is governed by `λ`. As `λ → 0` the update recovers the fast Gauss-Newton step, used when a trial step actually decreases the cost (close to the solution). As `λ → ∞` it degenerates to a short, safe step along the steepest-descent direction, `Δq ≈ −(1/λ) Jᵀe`, used when a step would otherwise increase the cost (far from the solution or near a singularity). Adapting `λ` each iteration — shrinking it on success, growing it on failure — gives LM an implicit **trust region**: the `λI` term lower-bounds the eigenvalues of the system matrix, guaranteeing it stays invertible and **bounding the step length so the end-effector cannot overshoot**. This damping is precisely why LM eliminates the oscillation that the bare pseudoinverse exhibits. The MATLAB core is

```matlab
grad = -J1' * err;            % steepest-descent direction
H    =  J1' * J1;             % Gauss-Newton Hessian approximation
dx   = -inv(H + lambda*eye(N)) * grad;   % LM damped step
PhiVec = PhiVec + dx;         % update joint angles
```

### 5.2 BFGS (Quasi-Newton)
BFGS avoids forming or inverting a Hessian altogether. It maintains a running estimate `H` of the *inverse* Hessian and refines it with a rank-two update that enforces the secant condition. With the step and gradient change

<div class="equation">
$$
\mathbf{s}_k = \mathbf{q}_{k+1} - \mathbf{q}_k,
\qquad
\mathbf{y}_k = \nabla f(\mathbf{q}_{k+1}) - \nabla f(\mathbf{q}_k),
\qquad
\rho_k = \frac{1}{\mathbf{y}_k^{\mathsf T}\mathbf{s}_k},
$$
</div>

the inverse-Hessian estimate evolves as

<div class="equation">
$$
\mathbf{H}_{k+1} = \big(\mathbf{I} - \rho_k \mathbf{s}_k \mathbf{y}_k^{\mathsf T}\big)\,\mathbf{H}_k\,\big(\mathbf{I} - \rho_k \mathbf{y}_k \mathbf{s}_k^{\mathsf T}\big) + \rho_k \mathbf{s}_k \mathbf{s}_k^{\mathsf T},
\qquad
\mathbf{q}_{k+1} = \mathbf{q}_k - \mathbf{H}_k \nabla f(\mathbf{q}_k).
$$
</div>

BFGS converges superlinearly and each iteration is cheap (no matrix inversion), but it has no built-in damping: far from the target it must repeatedly correct its posture, so its iteration count grows with reach distance even though each iteration is fast.

### 5.3 Method summary

<table>
  <thead>
    <tr><th>Solver</th><th>Step rule</th><th>Hessian handling</th><th>Best regime</th></tr>
  </thead>
  <tbody>
    <tr><td>Moore-Penrose</td><td>\(\Delta\mathbf q = \mathbf J^{+}\Delta\mathbf p\)</td><td>None (linear pseudoinverse)</td><td>Small, near-linear corrections</td></tr>
    <tr><td>BFGS</td><td>\(\Delta\mathbf q = -\mathbf H\nabla f\)</td><td>Recursive inverse-Hessian estimate</td><td>Speed-critical, moderate nonlinearity</td></tr>
    <tr><td>Levenberg-Marquardt</td><td>\(\Delta\mathbf q = -(\mathbf J^{\mathsf T}\mathbf J+\lambda\mathbf I)^{-1}\mathbf J^{\mathsf T}\mathbf e\)</td><td>Damped Gauss-Newton</td><td>Highly nonlinear, near-singular</td></tr>
  </tbody>
</table>

## 6. Experimental Protocol
I drove the end-effector to commanded targets at four increasing reach distances (`d = 1 … 4` in workspace units), wrapping each solve in `tic`/`toc` to record wall-clock convergence time and instrumenting the loop to count iterations to the error threshold. Each distance was sampled repeatedly to average out interface-click placement noise. All three solvers shared identical initial configurations, link parameters, and stopping tolerance, so the only variable was the update rule.

<figure class="align-center">
  <img src="/assets/images/projects/ik-cambridge/optimizer-comparison.png" alt="Convergence time versus reach distance for the three solvers">
  <figcaption>Convergence time vs reach distance. Moore-Penrose (green) slows as the target recedes; BFGS (red) is consistently fastest in raw time; Levenberg-Marquardt (blue) is the only solver whose time <em>decreases</em> with distance, as its adaptive damping relaxes toward fast Gauss-Newton steps once the residual shrinks.</figcaption>
</figure>

## 7. Results

### 7.1 Convergence time (seconds)

<table>
  <thead>
    <tr><th>Reach distance</th><th>BFGS</th><th>Moore-Penrose</th><th>Levenberg-Marquardt</th></tr>
  </thead>
  <tbody>
    <tr><td>1</td><td>0.0196</td><td>0.0430</td><td>0.0476</td></tr>
    <tr><td>2</td><td>0.0246</td><td>0.0496</td><td>0.0479</td></tr>
    <tr><td>3</td><td>0.0261</td><td>0.0523</td><td>0.0421</td></tr>
    <tr><td>4</td><td>0.0265</td><td>0.0530</td><td>0.0401</td></tr>
  </tbody>
</table>

### 7.2 Iterations to converge

<table>
  <thead>
    <tr><th>Reach distance</th><th>BFGS</th><th>Moore-Penrose</th><th>Levenberg-Marquardt</th></tr>
  </thead>
  <tbody>
    <tr><td>1</td><td>4.5</td><td>3</td><td>4</td></tr>
    <tr><td>2</td><td>6</td><td>4</td><td>5</td></tr>
    <tr><td>3</td><td>10</td><td>4</td><td>6</td></tr>
    <tr><td>4</td><td>12</td><td>4</td><td>7</td></tr>
  </tbody>
</table>

### 7.3 Analysis
The three solvers separate cleanly along the speed–stability axis.

**BFGS** posts the lowest raw solve times (0.0196–0.0265 s) but its iteration count climbs steeply with distance (4.5 → 12). The superlinear local convergence is real, yet without damping the method must repeatedly re-estimate posture far from the target, so the work per solve grows even as each iteration stays cheap.

**Moore-Penrose** holds an almost constant iteration count (~4) but its solve time *increases* with distance (0.043 → 0.053 s). Its purely linear approximation carries no curvature information, so as the reach grows more nonlinear the per-iteration linear-algebra cost dominates and the bare pseudoinverse becomes the least suitable for large or varying displacements.

**Levenberg-Marquardt** is the standout in the nonlinear regime. Its damping makes it the only solver whose convergence time *falls* as distance increases (0.0476 → 0.0401 s): far from the target it takes conservative, well-conditioned steps, then relaxes `λ` toward Gauss-Newton as the residual collapses. Iteration counts stay moderate (4 → 7), and crucially the `λI` regularization bounds each step so the end-effector approaches without the overshoot-and-correct signature of the pseudoinverse — **cutting overshoot and oscillation by more than 10%** relative to the fixed-threshold baseline, with comparable terminal accuracy and lower latency in the hardest reaches.

The computational-cost ordering is consistent with theory: Moore-Penrose is cheapest per iteration (no Hessian, no regularization) but least stable on nonlinear problems; BFGS is a strong compromise that improves nonlinear convergence at the price of more steps; LM carries the highest per-iteration overhead (regularized Gauss-Newton solve each step) but converts that overhead into robustness and the cleanest end-effector trajectory.

## 8. Gait Kinematics: What Governs Step Length
With the manipulator pinned at one foot, the same model becomes a single-stance leg, and stride can be analyzed from the **center of mass**. For component masses `mᵢ` located at link/joint positions `rᵢ`, the CoM is

<div class="equation">
$$
\mathbf{r}_{\text{com}}(\mathbf{q}) = \frac{\sum_{i} m_i \,\mathbf{r}_i(\mathbf{q})}{\sum_{i} m_i},
$$
</div>

and the step length is the horizontal CoM displacement between the initial and final stance configurations,

<div class="equation">
$$
\Delta s = \big| x_{\text{com}}(\mathbf{q}_{\text{final}}) - x_{\text{com}}(\mathbf{q}_{\text{initial}}) \big|.
$$
</div>

Sweeping each joint independently produced a clear, and initially counter-intuitive, decomposition. Varying the **intermediate (mid) joint** leaves step length essentially flat — the fitted slope is ≈ 0 (`Δs ≈ 0·θ + 0.375`), so the mid joint reshapes internal posture without translating the center of mass. By contrast, the **initial/final angle of joint 2** dominates, with step length following a near-quadratic power law

<div class="equation">
$$
\Delta s \approx 0.338\,\theta_2^{\,1.95} \;\approx\; \theta_2^{\,2},
$$
</div>

while simultaneously raising the center of gravity. The kinematic reading is that, for the stance geometry studied, joint 2 sets the angular spread of the two ground-contact links about the pinned foot, and the resulting horizontal foot-to-foot reach scales with the square of that opening angle — so a small change there produces a large change in stride, whereas the mid joint merely folds the body between fixed endpoints.

For gait synthesis this is directly actionable: stride length and CoM height — and therefore the stability margin across terrain — are controlled almost entirely by one joint's start/end configuration. Control authority and tuning effort should concentrate on joint 2 rather than being spread uniformly across the chain.

## 9. Conclusion
Built from the kinematics up, the project shows that the right way to solve inverse kinematics depends on the nonlinearity of the reach. The Moore-Penrose pseudoinverse is adequate and cheap for small, near-linear corrections; BFGS is attractive when raw solve time dominates and step count is tolerable; but for the highly nonlinear, large-displacement, near-singular reaching that real manipulators face, **Levenberg-Marquardt delivers the best overall balance of convergence speed, accuracy, and robustness** — its damping is what removes the overshoot and oscillation that the undamped pseudoinverse cannot avoid, improving those metrics by more than 10%. The companion gait analysis closes the loop on the locomotion side, reducing stride control to a single dominant, near-quadratic joint relationship.

Two extensions follow naturally: replacing the fixed convergence threshold with a **floating, per-iteration tolerance** to shave further latency, and validating both the solver ranking and the gait law on **physical hardware over uneven terrain**, where actuator dynamics and contact will test the simulation's predictions.

<script>
window.MathJax = {
  tex: { inlineMath: [['\\(','\\)']], displayMath: [['$$','$$']], processEscapes: true },
  options: { skipHtmlTags: ['script','noscript','style','textarea','pre','code'] }
};
</script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/3.2.2/es5/tex-mml-chtml.min.js" async></script>
