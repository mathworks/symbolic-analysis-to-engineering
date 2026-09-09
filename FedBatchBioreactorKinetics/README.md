# Fed-Batch Bioreactor Kinetics with Units and Engineering Handoff

This example shows how Symbolic Math Toolbox&trade; can connect kinetic theory to engineering workflows for a fed-batch bioreactor. It derives a temperature-dependent Michaelis-Menten/Monod-style rate law, checks units explicitly, generates reusable MATLAB&reg; functions, and reuses those functions in compact simulation, local linearization, state-space analysis, SimBiology&reg; rate-law reuse, and productivity analysis.

## Example Outline

The outline below mirrors the numbered sections in `FedBatchBioreactorKinetics.m`.

| Section | Live Script step | What to look for |
|---|---|---|
| 1 | Derive the kinetic rate law from enzyme-complex assumptions | Starts from the enzyme-mediated mechanism `E + S <-> C -> E + P`, applies the quasi-steady-state approximation, verifies the Michaelis-Menten form, and maps the saturation structure into a Monod-style growth law. |
| 2 | Add temperature dependence and inspect sensitivity | Adds the apparent Arrhenius temperature correction to the mapped growth law and uses symbolic differentiation to inspect temperature sensitivity. |
| 3 | Audit units before creating numeric functions | Converts flow, volume, temperature, activation energy, and gas constant values before numeric handoff. This includes explicit absolute-temperature conversion from Celsius to kelvin. |
| 4 | Verify the fed-batch balance dimensions | Explains the well-mixed tank balances, attaches units to each derivative term, and checks `dX/dt`, `dS/dt`, `dP/dt`, and `dV/dt` with `checkUnits`. |
| 5 | Convert realistic operating parameters to numeric magnitudes | Converts unit-bearing lab-scale parameters into numeric values in the agreed engineering unit system. |
| 6 | Build the symbolic fed-batch material balances | Builds the symbolic ODE right-hand side for biomass, substrate, product, and reactor volume. |
| 7 | Recover the batch model as a special case | Sets feed flow to zero as a boundary case and verifies that the fed-batch model reduces cleanly to the batch model. |
| 8 | Use symbolic algebra to separate concentration dilution from product mass | Shows why product concentration and total product mass respond differently to feed flow. This is the example's main iteration point before simulation or optimization. |
| 9 | Compute Jacobians for local linearization and sensitivity analysis | Derives symbolic state and input Jacobians from the same ODE right-hand side. |
| 10 | Generate reusable MATLAB functions | Generates compact numeric MATLAB functions from the symbolic rate laws, ODEs, Jacobians, and productivity expressions. |
| 11 | Simulate the fed-batch process using the generated RHS and Jacobian | Reuses the generated RHS and Jacobian in `ode15s` for a 12-hour process simulation. |
| 12 | Visualize concentration and product-mass trajectories | Plots concentration trajectories, reactor volume, and total product mass. |
| 13 | Evaluate a local perturbation model along the trajectory | Evaluates the generated Jacobian at the final simulated operating condition, shows the nonzero state derivative, and frames the matrices as a trajectory perturbation model rather than an equilibrium linearization. |
| 14 | Inspect local productivity sensitivities | Uses the generated productivity function and analytic gradient for a local sensitivity check without turning the example into an optimization workflow. |
| 15 | Hand off the generated Jacobian for local analysis | Maps the perturbation model to product concentration and total product mass outputs, summarizes the state-space handoff, and optionally packages it as an `ss` object when Control System Toolbox&trade; is available. |
| 16 | Validate the symbolic rate law for SimBiology reuse | Converts the unit-checked symbolic rate law into SimBiology-compatible names, values, units, and reaction-rate strings, then checks that every exported symbol has a mapped unit and value or initial condition. |
| 17 | Create a compact SimBiology handoff object when available | Creates a small `sbiomodel`, adds reactions, and assigns the generated expression strings to `ReactionRate` properties when SimBiology is installed. This remains an artifact check, not a full SimBiology simulation workflow. |
| 18 | Generated artifact summary | Summarizes the generated files and the downstream purpose of each one. |

## Generated MATLAB Functions

Running the Live Script generates compact numeric MATLAB functions:

| Generated file | Purpose |
|---|---|
| `bioreactorRates.m` | Temperature-dependent growth rate and temperature sensitivity |
| `fedBatchBioreactorRHS.m` | ODE right-hand side for simulation or downstream model reuse |
| `bioreactorJacobian.m` | State/input Jacobians for local linearization and sensitivity analysis |
| `bioreactorProductivity.m` | Algebraic product formation rate |
| `bioreactorProductivityGradient.m` | Analytic substrate and temperature productivity sensitivities |

These files are generated at runtime and ignored by source control.

## Downstream Handoff Points

The example uses the symbolic work in three downstream engineering contexts:

- Numeric simulation with `ode15s`
- Local linear and state-space analysis using generated Jacobian matrices
- SimBiology rate-law reuse using generated reaction-rate expressions and a lightweight symbol/unit handoff contract

The symbolic unit workflow follows the MathWorks units documentation:

- [Units of Measurement Tutorial](https://www.mathworks.com/help/symbolic/units-of-measurement-tutorial.html)
- [Units of Measurement](https://www.mathworks.com/help/symbolic/units-of-measurement.html)

## Quick Start

### Requirements

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2025a or later for plain-text Live Script support
- [Symbolic Math Toolbox](https://www.mathworks.com/products/symbolic.html)

Optional downstream context:

- Simulink, if you want to place the generated RHS/Jacobian in a MATLAB Function block
- SimBiology, optional, to create a compact model object from the generated rate expressions
- Control System Toolbox, optional, for packaging the generated local linearization as `ss` models

### Running the Example

1. Open MATLAB and navigate to this directory.
2. Open `FedBatchBioreactorKinetics.m` as a Live Script.
3. Run section by section, or run all.
4. Inspect the generated functions in the working directory.

## Files

| File | Description |
|---|---|
| `FedBatchBioreactorKinetics.m` | Main plain-text Live Script example. |
| `FedBatchBioreactorKinetics.pdf` | Existing exported reference copy. The source Live Script is authoritative after edits. |
| `.gitignore` | Ignores generated MATLAB functions and common MATLAB runtime artifacts. |
| `bioreactorRates.m` | Generated at runtime. Rate law and temperature sensitivity. |
| `fedBatchBioreactorRHS.m` | Generated at runtime. Numeric fed-batch ODE RHS. |
| `bioreactorJacobian.m` | Generated at runtime. Numeric state/input Jacobians. |
| `bioreactorProductivity.m` | Generated at runtime. Algebraic productivity evaluator. |
| `bioreactorProductivityGradient.m` | Generated at runtime. Productivity sensitivities. |

Copyright 2026 The MathWorks, Inc.
