# Symbolic Range Analysis for Hybrid-Electric Aircraft

This example derives, optimizes, and deploys range equations for a hybrid-electric regional aircraft: a roughly 50-seat configuration cruising at 25,000 ft and 280 kts, with a turbofan engine (SFC 0.6 lb/lbf/hr) supplemented by a 250 Wh/kg battery pack at 10% of gross weight.

The classical Breguet range equation assumes all propulsive energy comes from fuel, so aircraft weight decreases continuously throughout cruise. A hybrid-electric aircraft breaks that assumption: the battery contributes thrust power, but its mass stays constant. The example builds the modified range equation from first principles using Symbolic Math Toolbox, then carries the result through optimal energy split, sensitivity analysis, code generation, and uncertainty analysis.

The same workflow applies to other novel configurations where standard range equations do not exist: blended wing body, distributed electric propulsion, hydrogen fuel cell hybrids, or solar-electric concepts.

## Example Outline

### 1. Define the Hybrid-Electric Energy Model
Symbolic declaration of the aircraft physics: steady level cruise, split thrust power, fuel-only weight depletion, and constant battery mass.

### 2. Derive the Hybrid Range Equation
Symbolic integration of the cruise range equation. The result is a closed-form range expression parameterized by the fuel-powered thrust fraction $\phi$.

- `int` - integrate the range differential
- `simplify` - reduce the closed-form expression

### 3. Battery Constraint and Optimal Power Split
The battery energy balance determines the power split $\phi^*$ that simultaneously exhausts fuel and battery energy. A dimensionless battery-to-fuel energy ratio $\beta$ makes the result interpretable.

- `solve` - find optimal power split from energy balance
- `simplify` - express the result in compact symbolic form

### 4. Verify the Classical Breguet Limit
Substitute $\phi = 1$ to recover the fuel-only Breguet range equation. This limiting-case check verifies that the hybrid derivation is consistent with the classical model.

- `subs` - apply the fuel-only limit
- `simplify` - verify the symbolic difference is zero

### 5. Derive the Optimized Range
Substitute $\phi^*$ into the hybrid range equation. The optimized result separates into a classical fuel contribution plus a battery range bonus, making the engineering trade visible.

### 6. Evaluate a Reference Aircraft
Evaluate the closed-form expressions for a realistic regional-aircraft design point and sweep the power split to show battery-limited and fuel-limited regimes. Unit conversions are explicit constants so the symbolic workflow stays focused.

### 7. Sensitivity Analysis
Symbolic partial derivatives of optimized range $R^*$ with respect to cruise speed, L/D, SFC, electric efficiency, battery energy density, battery mass fraction, and fuel fraction. Elasticities compare parameters on a common percentage basis.

- `diff` - exact partial derivatives, not finite differences
- `subs` - evaluate sensitivities at the reference design point

### 8. Code Generation: Reusable Range Functions and C Expression
Convert symbolic expressions into optimized MATLAB&reg; functions via `matlabFunction`. The generated functions accept vectorized inputs so they can be called directly from sizing tools, mission planners, or Monte Carlo engines.

- `matlabFunction` - generates `hybridRange.m`, `hybridRangeSensitivity.m`, and `hybridOptimalPhi.m`
- `ccode` - emits a compact C expression for equation exchange with external modeling tools

### 9. Monte Carlo: Range Margin Under Uncertainty
Draw 50,000 parameter scenarios from calibrated distributions for L/D, SFC, battery energy density, electric efficiency, and cruise speed. One vectorized call to the generated range function evaluates the full ensemble, and the histogram shows how much margin remains against a reference range requirement.

- `makedist`, `truncate`, `random` - parameter distributions
- `histogram`, `xline` - visualize range distribution, requirement, and lower-tail margin

### 10. Variance Decomposition via Analytic Sensitivities
Use the generated sensitivity function to estimate which uncertain parameters dominate range variability. This shows the payoff of symbolic analysis: exact derivatives feed directly into first-order uncertainty propagation without parameter bumping.

## What Gets Generated

Running the example produces reusable MATLAB functions:

| Generated file | Signature | Use case |
|----------------|-----------|----------|
| `hybridRange.m` | `R = hybridRange(V, LD, SFC, eta_e, e_batt, W_batt_frac, xi, g)` | Optimal range with simultaneous depletion |
| `hybridRangeSensitivity.m` | `[dR_dV, dR_dLD, ...] = hybridRangeSensitivity(...)` | Analytic range sensitivities for uncertainty propagation |
| `hybridOptimalPhi.m` | `phi = hybridOptimalPhi(V, SFC, eta_e, e_batt, W_batt_frac, xi, g)` | Optimal fuel/electric power split for a design point |

The MATLAB functions accept vectorized inputs. The `ccode()` output is an equation-exchange artifact for external modeling tools; it is not intended as production or embedded C code.

## Downstream Workflow Connections

The generated functions are building blocks for engineering workflows:

### Aircraft Sizing and Trade Studies
`hybridRange.m` evaluates range across battery energy density, fuel fraction, electric efficiency, and aerodynamic design variables. This lets a sizing tool sweep thousands of candidate architectures without re-integrating the physics or duplicating the derivation.

### Mission Planning and Dispatch Analysis
`hybridOptimalPhi.m` gives the fuel/electric split that uses both energy stores efficiently for a given route condition. Mission planners can combine it with reserve policies, route length, payload, and speed constraints to screen feasible dispatch cases.

### Simulink / Simscape Energy Models
The generated range and optimal-split functions can be called from MATLAB Function blocks as analytic references inside higher-fidelity aircraft energy simulations. If the symbolic derivation changes, the generated functions update the downstream model without hand-transcribing equations.

### External Energy Models
`ccode(R_opt_explicit)` produces a C expression that could be wrapped in a Modelica external function for a non-MATLAB aircraft energy model. That lets an external tool reuse the same closed-form range equation without hand-transcribing the symbolic result.

### Range Margin Analysis
`hybridRange.m` evaluates the range distribution directly, while `hybridRangeSensitivity.m` maps uncertainty in L/D, SFC, battery energy density, electric efficiency, and cruise speed into first-order variance contributions. Together they show how symbolic expressions become reusable tools for requirement margin and risk analysis.

## Quick Start

### Requirements

- MATLAB R2025a or later
- Symbolic Math Toolbox&trade;
- Statistics and Machine Learning Toolbox&trade;

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`HybridElectricAircraftRange.m`** as a Live Script
3. Run section by section, or run all

The generated functions (`hybridRange.m`, `hybridRangeSensitivity.m`, `hybridOptimalPhi.m`) are written to the working directory at runtime.

## Files

| File | Description |
|------|-------------|
| `HybridElectricAircraftRange.m` | Main example (Live Script). Full workflow from symbolic derivation through range margin analysis. |
| `hybridRange.m` | Generated at runtime. Closed-form optimal hybrid-electric range function. |
| `hybridRangeSensitivity.m` | Generated at runtime. Analytic range sensitivities for all design parameters. |
| `hybridOptimalPhi.m` | Generated at runtime. Optimal power split from energy balance. |

Copyright 2026 The MathWorks, Inc.
