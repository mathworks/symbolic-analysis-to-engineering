# Relief Valve Sizing with Units and Engineering Handoff

This example shows how Symbolic Math Toolbox&trade; can connect compressible-flow derivation to a practical process-safety handoff. It derives ideal-gas relief-valve sizing equations, checks mixed plant units explicitly, generates reusable MATLAB&reg; functions, reuses those functions in upset-scenario screening, and applies the selected valve size to a Simscape&trade; Fluids&trade; model.

The example demonstrates an engineering handoff, not a certified API, ASME, or company-standard relief-system design method.

## Example Outline

### 1. Define a Representative Gas Relief Case

Defines an isobutane vapor relief case for a pressurized vessel using common plant units: psig-style pressures, Fahrenheit temperature, lbm/hr mass flow, and molecular weight in g/mol.

### 2. Derive the Ideal-Gas Mass-Flux Equations

Derives the choked and subcritical ideal-gas mass-flux expressions symbolically from pressure ratio, heat-capacity ratio, molecular weight, and absolute upstream state.

- `syms` and assumptions define physically meaningful positive variables.
- `simplify` keeps the symbolic mass-flux expressions inspectable.

### 3. Derive the Choked-Flow Criterion

Uses symbolic differentiation of the subcritical pressure-ratio factor to derive the critical ratio:

$$
r_\mathrm{crit} = \left(\frac{2}{k + 1}\right)^{k/(k - 1)}
$$

The generated classifier uses this criterion to decide whether each screened scenario is choked or subcritical.

### 4. Solve Symbolically for Required Area

Solves the mass-flow relationship `mdot = Cd*A*G` for required orifice area. The script keeps separate choked and subcritical area expressions, then combines them with `piecewise` for generated-function reuse.

### 5. Audit Units Before Extracting Numeric Magnitudes

Uses Symbolic Math Toolbox units to convert and check the reference case before numeric handoff.

- `symunit` defines physical units.
- `unitConvert` converts psi, lbm/hr, Fahrenheit, and in^2.
- `checkUnits` verifies that the symbolic area expression is compatible with area.
- `separateUnits` extracts numeric SI magnitudes for generated functions.

The example follows the MathWorks units documentation:

- [Units of Measurement Tutorial](https://www.mathworks.com/help/symbolic/units-of-measurement-tutorial.html)
- [Units of Measurement](https://www.mathworks.com/help/symbolic/units-of-measurement.html)

### 6. Quantify Common Unit Mistakes

The Live Script quantifies two mistakes that commonly appear in hand calculations and spreadsheet workflows:

- treating gauge pressure as absolute pressure,
- converting Fahrenheit as a temperature difference instead of an absolute temperature.

### 7. Compute Symbolic Area Sensitivities

Computes normalized area sensitivities with `diff` and `jacobian`. Choked-flow area has zero local sensitivity to backpressure, while the subcritical branch restores direct backpressure sensitivity.

### 8. Generate Reusable MATLAB Functions

Running the example produces compact numeric MATLAB functions:

| Generated file | Signature/use case |
|---|---|
| `criticalPressureRatio.m` | Critical pressure ratio as a function of heat-capacity ratio |
| `reliefIsChoked.m` | Logical choked-flow classifier |
| `reliefAreaGas.m` | Required gas relief area for scenario screening |
| `reliefAreaGasChoked.m` | Choked-only area expression for comparison |
| `reliefSizingElasticityChoked.m` | Normalized area sensitivities for choked flow |
| `reliefSizingElasticitySubcritical.m` | Normalized area sensitivities for subcritical flow |

These files are generated at runtime and ignored by source control.

### 9. Convert Upset Scenarios to Numeric Inputs

Converts the scenario table from plant-style units to the SI magnitudes expected by the generated functions.

### 10. Screen Scenarios with Generated Sizing Kernels

Reuses `criticalPressureRatio.m`, `reliefIsChoked.m`, and `reliefAreaGas.m` across representative upset scenarios. This is the first point where the symbolic derivation is used as ordinary numerical engineering code.

### 11. Select a Representative Standard Orifice

Converts each continuous required area into a discrete representative standard orifice using `selectStandardOrifice.m`. The example includes a small margin chart as a visual check of the selected sizes.

### 12. Evaluate Sensitivities at the Screened Cases

Evaluates the generated elasticity functions at each screened scenario. Choked cases use the choked sensitivity expression; the high-backpressure case uses the subcritical expression.

### 13. Audit a Choked-Flow Shortcut

The high-backpressure scenario is subcritical. A choked-only shortcut would under-size that case, so the workflow retains the subcritical branch and pressure-ratio logic.

### 14. Run a Numerical Margin Sweep

The final section uses the generated `reliefAreaGas.m` function in a numerical uncertainty sweep for the governing scenario. Ordinary numeric scenario inputs go into the generated sizing function, and the resulting area margins are plotted as a compact margin map.

### 15. Configure the Simscape Fluids Model

Opens `ReliefValveSizingSimscape.slx`, a small prepared Simscape Fluids model of a vessel relief transient. A controlled inlet mass-flow source pressurizes a constant-volume vessel, and the configured `Pressure Relief Valve (G)` vents to a downstream reservoir.

The vessel, source, gas, and reservoir setup is stored in the model. The section applies the selected standard area, discharge coefficient, and valve set pressure to the relief-valve block with `set_param`, then runs a short simulation and plots vessel pressure and relief mass flow. This remains lighter than a certified relief-system validation model; its purpose is to show exactly where the symbolic sizing result enters a downstream dynamic model.

## Quick Start

### Requirements

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2025a or later for plain-text Live Script support
- [Symbolic Math Toolbox](https://www.mathworks.com/products/symbolic.html)

Optional downstream context:

- Simulink, if you want to place the generated sizing function in a MATLAB Function block
- Simscape Fluids, if you want to open and configure the included handoff model
- Optimization Toolbox&trade;, if you want to replace the base-MATLAB standard-size selection with an integer program

### Running the Example

1. Open MATLAB and navigate to this directory.
2. Open `ReliefValveSizing.m` as a Live Script.
3. Run section by section, or run all.
4. Inspect the generated functions, the transient response plot, and the updated valve parameters in `ReliefValveSizingSimscape.slx`.

## Files

| File | Description |
|---|---|
| `ReliefValveSizing.m` | Main plain-text Live Script example. |
| `ReliefValveSizingSimscape.slx` | Prepared Simscape Fluids vessel-relief model with the valve block configured by Section 15. |
| `selectStandardOrifice.m` | Handwritten helper for representative standard-orifice selection. |
| `.gitignore` | Ignores generated MATLAB functions and common MATLAB runtime artifacts. |
| `criticalPressureRatio.m` | Generated at runtime. Critical pressure ratio. |
| `reliefIsChoked.m` | Generated at runtime. Choked-flow classifier. |
| `reliefAreaGas.m` | Generated at runtime. Required relief area. |
| `reliefAreaGasChoked.m` | Generated at runtime. Choked-only required area for shortcut comparison. |
| `reliefSizingElasticityChoked.m` | Generated at runtime. Choked-flow area elasticities. |
| `reliefSizingElasticitySubcritical.m` | Generated at runtime. Subcritical-flow area elasticities. |

Copyright 2026 The MathWorks, Inc.
