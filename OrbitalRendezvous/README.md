# Symbolic Maneuver Planning for Orbital Rendezvous

This example derives, deploys, and reuses closed-form maneuver planning equations for spacecraft proximity operations using the Clohessy-Wiltshire (Hill's) equations, the standard linear model for relative orbital motion near a circular reference orbit.

The Clohessy-Wiltshire equations are coupled linear ODEs with exact closed-form solutions via `dsolve`. That makes maneuver delta-v, bounded relative-motion conditions, and burn-error sensitivity available as symbolic functions of transfer time, relative geometry, and orbital mean motion. This parametric form gives the engineering trade space directly, not one propagated trajectory at a time.

The same workflow applies to formation flying, inspection approaches, passive-safety hold points, debris-avoidance maneuvers, and early-stage rendezvous trade studies where linearized relative motion is an appropriate first model.

## Example Outline

### 1. The Clohessy-Wiltshire Equations
Symbolic declaration of the linearized relative-motion ODEs in the LVLH frame: radial (`x`, R-bar), along-track (`y`, V-bar), and cross-track (`z`, H-bar) dynamics coupled through the mean motion `n`.

### 2. Analytic General Solution via `dsolve`
`dsolve` produces the exact closed-form CW solution with arbitrary initial conditions. The example isolates the secular along-track drift term and derives the no-drift condition for bounded relative motion.

- `dsolve` - closed-form ODE solution for the coupled in-plane system
- `limit`, `simplify` - isolate the secular drift rate
- `solve` - derive the no-drift condition as a constraint on initial velocity

### 3. Impulsive Maneuver Delta-V
Given initial and final relative positions and a transfer time `T`, the script solves the analytic CW solution for the required departure velocity. Both departure and arrival braking delta-v are retained as symbolic functions of timing, geometry, and orbital rate.

- `subs`, `solve` - endpoint boundary-value problem for required velocity
- `simplify` - closed-form departure and arrival delta-v expressions

### 4. Reference Mission
An ISS-like servicing scenario provides realistic numbers: a chaser starts 1 km behind and 50 m below the target docking port in a 420 km circular orbit.

### 5. Code Generation for Reuse
`matlabFunction` converts the symbolic expressions into optimized MATLAB&reg; functions. These generated functions are the handoff from first-principles derivation to repeated engineering analysis.

- `matlabFunction` - generates `departureVelocity.m`, `arrivalVelocity.m`, `maneuverDeltaV.m`, and `cwTrajectory.m`

### 6. Fuel-Optimal Transfer Timing
The generated delta-v function is evaluated over a transfer-time sweep. Near-singular transfer times are marked and masked in the plot so the practical delta-v trade remains visible while the underlying analytic singularities are still acknowledged.

### 7. Safety Ellipse Analysis
The symbolic no-drift condition is substituted back into the analytic solution. For the pure-hold case with zero radial velocity, the script derives the safety ellipse identity directly:

`x^2/x0^2 + (y-y0)^2/(2*x0)^2 = 1`

The visualization code is kept in helper functions so the visible section stays focused on the symbolic result.

### 8. Sensitivity Analysis
The symbolic Jacobian of arrival position with respect to departure velocity gives the exact maneuver sensitivity matrix. The generated sensitivity function is swept across transfer time to show how departure burn errors are amplified by timing. The plot focuses on worst-case miss distance per 1 cm/s velocity error and marks the selected transfer time.

- `jacobian` - exact partial derivatives, not finite-difference approximations
- `svd` - worst-case direction of burn-error amplification
- `matlabFunction` - generates `maneuverSensitivity.m`

### 9. Compact Uncertainty Reuse Check
A short Monte Carlo section demonstrates another downstream workflow: vectorized propagation of departure velocity errors through the generated trajectory function. It is intentionally framed as a reuse demonstration, not as a certification claim that the simple two-impulse transfer meets final docking dispersions.

## What Gets Generated

Running the example produces deployable MATLAB functions:

| Generated file | Signature | Use case |
|----------------|-----------|----------|
| `departureVelocity.m` | `[vx0, vy0] = departureVelocity(n, T, x0, y0, xf, yf)` | Required departure velocity for a transfer |
| `arrivalVelocity.m` | `[vx_arr, vy_arr] = arrivalVelocity(n, T, x0, y0, xf, yf)` | Arrival velocity at the target point |
| `maneuverDeltaV.m` | `[dv_dep, dv_arr] = maneuverDeltaV(n, T, x0, y0, xf, yf)` | Two-impulse delta-v magnitudes |
| `cwTrajectory.m` | `[x, y] = cwTrajectory(n, t, x0, y0, vx0, vy0)` | Analytic CW trajectory propagation |
| `maneuverSensitivity.m` | `J = maneuverSensitivity(n, T)` | 2-by-2 sensitivity matrix `d(xf,yf)/d(vx0,vy0)` |

All generated functions accept vectorized inputs where the corresponding symbolic expression supports vectorized evaluation.

## Downstream Workflow Connections

The generated functions are building blocks for production engineering workflows:

### Rendezvous Mission Design
`maneuverDeltaV.m` and `departureVelocity.m` support rapid timing sweeps for hold-point-to-target transfers. Designers can evaluate thousands of candidate transfer times from the same derived expression, identify low-delta-v windows, and avoid singular transfer geometries without rerunning an ODE propagator for each case.

### Passive Safety and Hold-Point Design
The no-drift condition and safety ellipse identity give analytic constraints for bounded relative orbits. These expressions help choose R-bar/V-bar offsets and natural-motion hold points before moving to higher-fidelity nonlinear propagation.

### Guidance, Navigation, and Control Margin Analysis
`maneuverSensitivity.m` maps departure velocity errors to arrival position errors. This supports early burn-execution tolerance studies, actuator sizing trades, and navigation-error budgets using exact partial derivatives rather than finite differences.

### Monte Carlo and Trade Studies
`cwTrajectory.m` evaluates many perturbed departure velocities in a single vectorized call. That makes it useful for lightweight dispersion studies and for checking whether the analytic sensitivity prediction matches sampled uncertainty propagation.

## Quick Start

### Requirements

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2024b or later to run the script
- MATLAB R2025a or later to open or edit it as a plain-text Live Script
- [Symbolic Math Toolbox&trade;](https://www.mathworks.com/products/symbolic.html)

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`OrbitalRendezvous.m`** as a Live Script
3. Run section by section, or run all

The generated functions (`departureVelocity.m`, `arrivalVelocity.m`, `maneuverDeltaV.m`, `cwTrajectory.m`, `maneuverSensitivity.m`) are written to the working directory at runtime and ignored by source control.

## Files

| File | Description |
|------|-------------|
| `OrbitalRendezvous.m` | Main example (plain-text Live Script). Full workflow from CW equations through generated functions and compact downstream reuse studies. |
| `departureVelocity.m` | Generated at runtime. Required departure velocity for a transfer. |
| `arrivalVelocity.m` | Generated at runtime. Arrival velocity at the target point. |
| `maneuverDeltaV.m` | Generated at runtime. Two-impulse delta-v magnitudes. |
| `cwTrajectory.m` | Generated at runtime. Analytic CW trajectory propagation. |
| `maneuverSensitivity.m` | Generated at runtime. Maneuver sensitivity Jacobian. |

Copyright 2026 The MathWorks, Inc.
