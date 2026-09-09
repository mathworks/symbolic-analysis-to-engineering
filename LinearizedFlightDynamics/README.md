# Linearized Longitudinal Flight Dynamics

This example derives, deploys, and reuses a longitudinal aircraft flight-dynamics model using symbolic equations from first principles.

The workflow starts with aerodynamic force and moment coefficients, writes the translational dynamics in wind axes, trims a transport aircraft at cruise, computes exact symbolic A and B Jacobians, and then uses the structure of those derivatives to explain which aerodynamic terms drive stability. The same symbolic model is extended with transonic drag and Mach-dependent pitching moment, then generated as reusable MATLAB&reg; functions for downstream simulation, control design, and uncertainty analysis.

The example is intentionally compact: realistic enough to look like an aerospace workflow, but focused on showing why symbolic analysis is useful before moving into higher-fidelity aircraft models.

## Example Outline

### 1. Longitudinal Aircraft Equations of Motion
Build a 3DOF longitudinal model with states $V$, $\alpha$, $q$, and $\theta$, and inputs elevator deflection and thrust. Because $V$ and $\alpha$ are wind-axis states, the translational equations use wind-axis axial and normal force balance directly.

### 2. Cruise Trim and Linearization
Use Aerospace Toolbox `atmosisa` for FL350 conditions, solve exact steady-level trim, and compute symbolic Jacobians:

- `vpasolve` - trim angle of attack and elevator from force and moment balance
- `jacobian` - exact A and B matrices
- `subs`, `double` - numeric state-space matrices at the trim point

### 3. Stability-Derivative Dominance
Decompose $M_\alpha$ into additive symbolic terms and evaluate each contribution. This shows how much pitch stiffness comes from intrinsic aerodynamic-center moment slope versus lift acting through the CG offset.

- `expand`, `children` - term-by-term stability derivative decomposition
- `diff` - exact sensitivity to aerodynamic coefficients and CG location

### 4. Transonic Regime Extension
Add a piecewise wave-drag model and a Mach-dependent pitching-moment increment. Re-trim the aircraft and compare subsonic versus transonic derivatives, including the nonzero $M_u$ term associated with Mach tuck.

- `piecewise` - drag-divergence and Mach-tuck model branches
- `jacobian` - re-linearization after model extension

### 5. Code Generation for Downstream Use
Generate deployable MATLAB functions for the nonlinear equations of motion and the local state-space model. This turns the symbolic derivation into reusable engineering artifacts.

- `matlabFunction` - generates simulation and A/B evaluation functions

### 6. Stability-Derivative Uncertainty
Propagate uncertainty in aerodynamic coefficients through the generated state-space function. Modal parameter histograms and sample bounds show how wind-tunnel scatter maps into short-period and phugoid behavior.

## What Gets Generated

Running the example produces reusable MATLAB functions:

| Generated file | Signature | Use case |
|----------------|-----------|----------|
| `longitudinalEOM.m` | `xdot = longitudinalEOM(...)` | Nonlinear transonic longitudinal equations of motion |
| `longitudinalStateSpace.m` | `[A,B] = longitudinalStateSpace(...)` | Local A/B matrices for trim sweeps, control design, and Monte Carlo studies |

The generated files are written to the working directory at runtime and ignored by source control.

## Downstream Workflow Connections

### Flight Controls
The generated A/B matrices are the direct handoff to control-law design. They can feed pole-placement, LQR, robust-control, or handling-qualities workflows without re-deriving the aircraft equations.

### Simulink and Flight Simulation
`longitudinalEOM.m` can be used in a MATLAB Function block or as the right-hand side for an ODE simulation. Updating the symbolic model updates the generated simulation code from the same derivation.

### Envelope and Margin Analysis
Because the model remains parametric, Mach, altitude, CG, and aerodynamic coefficient sweeps are structured substitutions rather than copy-pasted numeric models. The example demonstrates this with transonic re-linearization and Monte Carlo uncertainty.

### Traceability
The stability-derivative formulas provide traceability from a modal result back to aerodynamic data. For example, $M_\alpha$ can be traced to the aerodynamic-center moment slope and the lift-CG coupling term instead of being treated as a black-box number.

## Quick Start

### Requirements

- MATLAB R2025a or later for plain-text Live Script format
- Symbolic Math Toolbox&trade;
- Aerospace Toolbox for `atmosisa`

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`LinearizedFlightDynamics.m`** as a Live Script
3. Run section by section, or run all

The generated functions (`longitudinalEOM.m`, `longitudinalStateSpace.m`) are written to the working directory at runtime.

## Files

| File | Description |
|------|-------------|
| `LinearizedFlightDynamics.m` | Main example. Full workflow from symbolic EOM through trim, A/B linearization, transonic extension, code generation, and uncertainty analysis. |
| `longitudinalEOM.m` | Generated at runtime. Nonlinear transonic equations of motion. |
| `longitudinalStateSpace.m` | Generated at runtime. A/B state-space matrices from the symbolic Jacobians. |

Copyright 2026 The MathWorks, Inc.
