# Symbolic Quarter-Car Dynamics for Active Suspension Design

This example derives, analyzes, and reuses a 2-DOF quarter-car suspension model using Newton's laws and Symbolic Math Toolbox&trade;. The model is the standard early-stage ride/road-holding abstraction used before moving to higher-fidelity simulations.

The symbolic value is traceability: body acceleration, tire deflection, characteristic-polynomial coefficients, and damping sensitivities remain formulas until the workflow needs numeric design decisions. That makes the passive damping compromise visible, then lets the same derived expressions feed a compact active-control comparison, generated MATLAB&reg; functions, and platform sweeps.

The active controller is intentionally framed as a short downstream illustration: it reduces the body-bounce-band response while exposing the tire-deflection tradeoff and actuator-bandwidth effect.

## Example Outline

### 1. Quarter-Car Equations of Motion
Symbolic derivation of the sprung and unsprung mass equations from the free-body model.

### 2. Laplace-Domain Transfer Functions
`solve` produces exact road-displacement transfer functions for body acceleration and tire deflection.

- `solve` -- algebraic solution for $Z_s(s)$ and $Z_u(s)$
- `simplify` -- compact transfer-function forms

### 3. Characteristic Polynomial
Extract the fourth-order denominator and show how mass, stiffness, and damping enter the dynamics.

### 4. Reference Vehicle and Frequency Bands
Representative sedan quarter-car parameters define the body-bounce, harshness, and wheel-hop regions used for numeric design.

### 5. Passive Damping Trade Space
Parameter sweep and symbolic sensitivities show the passive compromise: more damping reduces body-bounce response and tire deflection, but increases high-frequency acceleration harshness.

- `diff` -- exact derivatives with respect to damping ratio
- `subs` -- evaluation at representative modal frequencies

### 6. Skyhook Active Suspension with Actuator Dynamics
Derive closed-loop transfer functions for a skyhook force command with a first-order actuator lag.

### 7. Compact Control System Toolbox Reuse
Convert symbolic transfer functions to `tf` models, use `getPeakGain` for continuous-frequency design metrics, and use `bodeplot` for a passive-versus-active comparison plot.

### 8. Code Generation: Reusable Transfer-Function Evaluator
Convert the symbolic body-acceleration transfer function into a deployable MATLAB function via `matlabFunction`.

- `bodyAccelTF.m` -- transfer-function evaluator for parameter studies

### 9. Generated Function Reuse: Platform Mass Sweep
Use the generated `bodyAccelTF.m` function for a sprung-mass design sweep without re-solving the symbolic equations.

## What Gets Generated

Running the example produces deployable MATLAB functions:

| Generated file | Signature | Use case |
|----------------|-----------|----------|
| `bodyAccelTF.m` | `H = bodyAccelTF(s, cs, ks, kt, ms, mu)` | Vectorized body-acceleration transfer-function evaluation for platform and damping studies |

The generated files are written to the working directory at runtime and are ignored by the example's `.gitignore`.

## Downstream Workflow Connections

The generated functions and symbolic expressions are building blocks for production engineering workflows:

### Control System Toolbox&trade;: Frequency-Domain Design
The example converts symbolic transfer functions to named `tf` models, uses `getPeakGain` for grid-independent design metrics, and uses `bodeplot` for response visualization. Because the transfer functions are derived from first principles, changes to assumptions or sign conventions propagate directly into the control-design model.

### Vehicle Platform Studies
`bodyAccelTF.m` evaluates body-acceleration response over vehicle mass, spring, tire, and damping variants without re-running symbolic algebra. The example demonstrates this with a sprung-mass sweep.

## Quick Start

### Requirements

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2024b or later
- [Symbolic Math Toolbox](https://www.mathworks.com/products/symbolic.html)
- [Control System Toolbox](https://www.mathworks.com/products/control.html)

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`QuarterCarActiveSuspension.m`** as a Live Script
3. Run section by section, or run all

The generated function (`bodyAccelTF.m`) is written to the working directory at runtime.

## Files

| File | Description |
|------|-------------|
| `QuarterCarActiveSuspension.m` | Main example (Live Script). Full workflow from Newton's laws through symbolic analysis, compact control comparison, and generated-function reuse. |
| `bodyAccelTF.m` | Generated at runtime. Vectorized body-acceleration transfer-function evaluator. |

Copyright 2026 The MathWorks, Inc.
