# Symbolic Attitude Dynamics for Spacecraft Slew Maneuver Planning

This example derives, deploys, and validates closed-form slew time equations for spacecraft attitude maneuvers using Euler's rotational dynamics, the foundational model for reaction-wheel-based attitude determination and control systems (ADCS).

The eigenaxis slew problem reduces to a scalar double-integrator ODE with torque and rate constraints. This means slew time, rate profiles, and sensitivity to inertia/actuator degradation all come out as symbolic functions of the design parameters. That parametric form gives you the full actuator-sizing trade space in one expression, not one timeline at a time.

The same workflow applies to any constrained rotational maneuver: space telescope retargeting, antenna pointing, solar array gimbal scheduling, or pre-maneuver attitude alignment for orbital burns.

## Example Outline

### 1. Euler's Equations of Rotational Motion
Symbolic derivation of rigid-body rotational dynamics for a spacecraft with principal-axis-aligned inertia tensor. The full 3D coupled nonlinear system: $I\dot{\omega} + \omega \times (I\omega) = \tau$.

### 2. Eigenaxis Slew: Reduction to Scalar Dynamics
For rotation about a single principal axis (the standard reaction wheel maneuver mode), the gyroscopic coupling terms vanish. The dynamics reduce to the double-integrator $I\ddot{\theta} = \tau(t)$.

### 3. Time-Optimal (Bang-Bang) Slew Profile
`dsolve` produces the exact piecewise-constant-torque solution: full positive torque for the first half, full negative for the second. Closed-form expressions for angle, rate, and minimum slew time.

- `dsolve` — closed-form solution for constant-acceleration phases
- `solve` — minimum slew time from midpoint boundary condition

### 4. Rate-Limited (Trapezoidal) Slew Profile
Add the realistic maximum angular rate constraint (star tracker acquisition, structural flex, momentum capacity). Three-phase profile: accelerate, coast, decelerate. Exact symbolic transition times and coast duration.

- `solve` — coast time from total-angle constraint
- `piecewise` — regime-dependent slew time expression

### 5. Parametric Slew Time
Slew time as a symbolic function of four parameters: angle $\Theta$, inertia $I$, max torque $\tau_{\max}$, and max rate $\omega_{\max}$. The regime crossover angle $\Theta^* = I\omega_{\max}^2/\tau_{\max}$ determines which constraint dominates.

### 6. Reference Mission: Agile Earth-Observing Satellite
Realistic parameters for a high-resolution agile imaging platform (500 kg class, reaction wheels, star tracker rate limit). Slew times evaluated for typical cross-track retargeting angles (5°–45°).

### 7. Code Generation: Deployable Slew Planner
Convert symbolic expressions into optimized MATLAB&reg; functions via `matlabFunction`. The generated slew planner accepts vectorized inputs, so you can evaluate hundreds of target-to-target slew times in one call. The angle profile is then fed into Aerospace Toolbox `quaternion` objects to produce a full 3D attitude trajectory, demonstrating the symbolic-to-simulation bridge.

- `matlabFunction` — generates `slewTimeKernels.m`, `slewTime.m`, `slewRateProfileTrap.m`, `slewRateProfileBB.m`
- `quaternion`, `rotatepoint` — Aerospace Toolbox 3D attitude propagation from symbolic eigenaxis profile

### 8. Sensitivity Analysis: Inertia Growth & Actuator Degradation
Symbolic partial derivatives of slew time with respect to inertia, torque, and rate limit. Quantifies mission-life impact: how much does a +10% inertia growth or -15% torque loss affect the timeline? Verified via `vpa`: the analytic derivative matches a 32-digit finite-difference quotient to full precision, providing certification-grade traceability.

- `diff` — exact partial derivatives, not finite-difference approximations
- `vpa` — 32-digit verification of analytic sensitivity against finite-difference
- `matlabFunction` — generates `slewTimeSensitivity.m`

### 9. Pointing Budget Decomposition
Symbolic RSS error model for post-slew pointing stability: star tracker noise, reaction wheel jitter, structural flex, thermal distortion. Sensitivity of total pointing error to each contributor identifies where to invest engineering margin. Variance decomposition visualized as a horizontal bar chart.

- `diff` — sensitivity of total pointing error to each source

### 10. Multi-Target Scheduling
Given a sequence of imaging targets in one orbital pass, the generated slew planner computes all inter-target transition times. Timeline visualization and end-of-life capacity analysis show how actuator sizing decisions propagate to mission-level imaging throughput.

## What Gets Generated

Running the example produces deployable MATLAB functions:

| Generated file | Signature | Use case |
|----------------|-----------|----------|
| `slewTime.m` | `t_slew = slewTime(Theta, I, tau_max, omega_max)` | Slew time for given parameters (vectorized) |
| `slewTimeKernels.m` | `[t_bb, t_trap, Theta_star] = slewTimeKernels(...)` | Symbolic core: both regime expressions |
| `slewRateProfileTrap.m` | `omega = slewRateProfileTrap(t, Theta, alpha_max, omega_max)` | Trapezoidal rate profile evaluation |
| `slewRateProfileBB.m` | `omega = slewRateProfileBB(t, alpha_max, Theta)` | Bang-bang rate profile evaluation |
| `slewTimeSensitivity.m` | `[dI, dtau, domega] = slewTimeSensitivity(Theta, I, tau_max, omega_max)` | Partial derivatives for sensitivity analysis |

All functions accept vectorized inputs. C code equivalents are also available via `ccode()`.

## Downstream Workflow Connections

The generated functions are building blocks for production engineering workflows:

### Aerospace Toolbox: 3D Attitude Propagation
The example demonstrates this directly: the symbolically-derived angle profile is converted into a quaternion trajectory using Aerospace Toolbox's `quaternion` objects and `rotatepoint`. This bridges 1D eigenaxis planning (symbolic, parametric) with full 3D attitude simulation (numeric, mission-specific). The generated `slewRateProfileTrap.m` or `slewRateProfileBB.m` can produce reference rate commands for any ADCS simulation built on Aerospace Toolbox quaternion kinematics.

### Simulink/Simscape: ADCS Simulation
The generated `slewRateProfileTrap.m` and `slewRateProfileBB.m` drop directly into a MATLAB Function block as reference trajectory generators for closed-loop ADCS simulation. The slew planner provides the commanded attitude profile; Simulink&reg; and Simscape&reg; model the reaction wheel dynamics, flex-body coupling, and control loop that tracks it. Because the profile functions are generated from symbolic expressions, updating the derivation (e.g., adding a jerk limit) automatically updates the Simulink reference.

### Mission Planning & Scheduling Tools
`slewTime.m` is the key integration point: given a target observation schedule (sequence of off-nadir angles), one vectorized call returns all inter-target slew times. This feeds directly into scheduling optimizers (genetic algorithms, constraint solvers) that maximize daily imaging throughput subject to power, thermal, and ground contact constraints. The example demonstrates this with an 8-target orbital pass.

### Monte Carlo & Margin Analysis
`slewTimeSensitivity.m` enables analytic uncertainty propagation without simulation: given probability distributions on inertia (fuel slosh, appendage deployment) and available torque (wheel degradation curves), the sensitivity Jacobian maps parameter uncertainties directly to slew time margin. The example shows this for end-of-life degradation scenarios. For full Monte Carlo, `slewTime.m` evaluates thousands of parameter draws in a single vectorized call.

## Quick Start

### Requirements

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2024b or later
- [Symbolic Math Toolbox&trade;](https://www.mathworks.com/products/symbolic.html)
- [Aerospace Toolbox](https://www.mathworks.com/products/aerospace-toolbox.html) (for quaternion attitude propagation section)

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`SpacecraftAttitudeSlew.m`** as a Live Script
3. Run section by section, or run all

The generated functions (`slewTime.m`, `slewTimeKernels.m`, `slewRateProfileTrap.m`, `slewRateProfileBB.m`, `slewTimeSensitivity.m`) are written to the working directory at runtime.

## Files

| File | Description |
|------|-------------|
| `SpacecraftAttitudeSlew.m` | Main example (Live Script). Full workflow from Euler's equations through mission timeline analysis. |
| `slewTime.m` | Generated at runtime. Vectorized slew time (both regimes via logical indexing). |
| `slewTimeKernels.m` | Generated at runtime. Symbolic core: bang-bang time, trapezoidal time, crossover angle. |
| `slewRateProfileTrap.m` | Generated at runtime. Trapezoidal angular rate profile. |
| `slewRateProfileBB.m` | Generated at runtime. Bang-bang angular rate profile. |
| `slewTimeSensitivity.m` | Generated at runtime. Sensitivity partial derivatives. |
