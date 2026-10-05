# Symbolic Recurrence Solving for Macro-Financial Models

Closed-form analysis of dynamic economic systems using Symbolic Math Toolbox&trade; from first-principles derivation through sensitivity formulas to downstream Monte Carlo deployment.

The same derive-then-deploy pattern extends to other financial modeling problems governed by recurrences, such as debt sustainability models, discrete-time portfolio rebalancing, and loan amortization with variable rates.

## New in R2026a

The `solveRecurrence` function solves linear recurrence relations and systems in closed form. This example demonstrates three modes:

- Single linear recurrence with initial conditions and symbolic parameters
- System of linear recurrences using a 2x2 macro-financial VAR
- Nonlinear recurrence workflow: derive a steady state, linearize, then solve the local recurrence

## Example Outline

### 1. Capital Accumulation: Single Linear Recurrence

Solves

```math
k_{n+1} = \lambda k_n + c
```

for the closed-form path `k_n` as a function of period `n`, retention rate `lambda`, investment flow `c`, and initial capital `k0`.

- `solveRecurrence` produces the exact solution
- `matlabFunction` converts the symbolic expression to a numeric function
- Visualization shows convergence to steady state across parameter values

### 2. Macro-Financial VAR: 2x2 Recurrence

Uses a reduced-form macro-financial transition system for output gap and credit spread, written component-wise as:

```math
\hat{y}_{n+1} = \rho_y \hat{y}_n - \gamma_q q_n
```

```math
q_{n+1} = -\gamma_y \hat{y}_n + \rho_q q_n
```

This is an ordinary recurrence for predetermined state variables. It is not a forward-looking New Keynesian DSGE model.

- `solveRecurrence` solves the 2x2 system directly
- Calibrated shock propagation shows the response to a credit-spread shock
- Symbolic eigenvalues support a stability check as credit-spread persistence changes

### 3. Solow Growth Model: Nonlinear Recurrence via Linearization

The Solow growth recurrence

```math
k_{n+1} = s k_n^\alpha + (1-\delta)k_n
```

has no general closed form. The example shows a standard symbolic workflow:

- Derive the steady state `k* = (s/delta)^(1/(1-alpha))`
- Differentiate the transition map to obtain the local convergence rate `lambda*`
- Use `solveRecurrence` on the linearized deviation recurrence
- Differentiate the deployed terminal-capital formula to obtain analytic sensitivities

### 4. Downstream Deployment: Monte Carlo Stress Test

The symbolic results feed directly into Monte Carlo analysis:

- `matlabFunction` generates optimized `.m` files from symbolic formulas
- 50,000 parameter scenarios are drawn from calibrated distributions
- One vectorized function call evaluates the linearized Solow terminal-capital formula across all scenarios
- Analytic terminal-capital sensitivities are computed without finite-difference bump-and-revalue runs

## What Gets Generated

Running the example writes deployable MATLAB functions to the working directory:

| Generated file | Signature | Use case |
| --- | --- | --- |
| `capitalPath.m` | `k_n = capitalPath(n, lambda, c, k0)` | Closed-form scalar recurrence for capital accumulation |
| `solowTerminalCapital.m` | `k_terminal = solowTerminalCapital(n, k_init, s, alpha, delta)` | Linearized Solow terminal capital at period `n` |
| `solowTerminalSensitivity.m` | `[k_terminal, dkds, dkda, dkdd] = solowTerminalSensitivity(n, k_init, s, alpha, delta)` | Terminal capital and analytic sensitivities with respect to `s`, `alpha`, and `delta` |

The Solow deployment is a local approximation around the steady state. For large deviations from steady state, compare it against direct nonlinear simulation.

## Quick Start

### Requirements

- MATLAB&reg; R2026a or later
- Symbolic Math Toolbox
- Statistics and Machine Learning Toolbox&trade;

### Running the Example

1. Open MATLAB and navigate to this directory.
2. Open `SymbolicEconomicDynamics.m` as a Live Script.
3. Run section by section, or run all.

The generated functions are written to the working directory at runtime.

## Files

| File | Description |
| --- | --- |
| `SymbolicEconomicDynamics.m` | Main plain-text Live Script. Full workflow from symbolic recurrence solving through Monte Carlo deployment. |
| `capitalPath.m` | Generated scalar recurrence function. |
| `solowTerminalCapital.m` | Generated linearized Solow terminal-capital function. |
| `solowTerminalSensitivity.m` | Generated linearized Solow terminal-capital sensitivity function. |

Copyright 2026 The MathWorks, Inc.