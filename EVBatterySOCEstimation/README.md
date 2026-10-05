# EV Battery Equivalent Circuit and SOC Estimation

This example derives, deploys, and validates a 2-RC Thevenin equivalent circuit model for lithium-ion battery SOC estimation using first-principles circuit equations and Symbolic Math Toolbox&trade;.

The teaching focus is the engineering workflow: derive the model once symbolically, inspect the exact time-domain and frequency-domain forms, linearize the measurement equation for observer design, then generate small MATLAB&reg; functions that can be reused in Simulink&reg;, calibration, or embedded-code workflows. The point is not to build a complete production BMS, but to show how symbolic analysis removes duplicated hand algebra and keeps the downstream implementation traceable to the physics.

The same workflow applies to HPPC pulse fitting, EIS parameter identification, reduced-order observer design, HIL testing, and Simscape&trade; Battery&trade; validation.

## Example Outline

### 1. Thevenin 2-RC Equivalent Circuit Model
Symbolic derivation of the polarization-voltage ODEs for the fast charge-transfer and slow diffusion branches. `dsolve` produces the exact current-step response and terminal-voltage expression.

- `dsolve` - exact RC branch time response
- `simplify` - readable terminal-voltage expression

### 2. Impedance Spectroscopy Model
Derive the current-to-voltage impulse response for each RC branch, use `laplace` to obtain the impedance model, and use `partfrac` to expose the independently identifiable electrochemical contributions.

- `laplace` - impulse response to impedance
- `partfrac` - separate fast and slow RC contributions
- `ilaplace` - connect frequency-domain impedance back to time-domain response

### 3. SOC-Dependent Parameters
Use `piecewise` to define a compact OCV-SOC curve and SOC-dependent ohmic resistance. These expressions are reused later in the generated voltage-prediction function rather than being reimplemented by hand.

- `piecewise` - OCV and resistance schedules

### 4. Linearization for SOC Estimation
Linearize the output equation around the mid-SOC operating region and compute the state and output Jacobians needed for local observer analysis.

- `taylor` - local OCV approximation
- `jacobian` - state and measurement matrices for EKF/Luenberger workflows

### 5. Analytical Parameter Sensitivities
Differentiate voltage and SOC error expressions with respect to uncertain parameters. This shows how symbolic derivatives support calibration priorities and margin analysis without finite-difference scripts.

- `diff` - exact sensitivities to resistance and capacity uncertainty

### 6. Linearized Observer for Real-Time SOC Estimation
Use the symbolic Jacobians to build exact ZOH discrete-time matrices and run a short fixed-gain observer simulation. The observer gain is intentionally treated as a downstream calibration choice so the example stays focused on symbolic modeling.

- `expm`, `int` - exact discrete-time state update
- `rank` - local observability check

### 7. Code Generation for BMS Algorithm Handoff
Convert the derived equations into compact generated MATLAB functions. The generated voltage function uses the same `piecewise` OCV and resistance model derived earlier; the generated output Jacobian provides the EKF measurement linearization.

- `matlabFunction` - generates reusable MATLAB functions
- `ccode` - optional C export for third-party tools or hand integration

### 8. Downstream Workflow Connections
Use the symbolic impedance model for EIS parameter fitting, show the generated functions as the computational core of a Simulink MATLAB Function block, and describe how that observer block can be validated against a Simscape Battery plant model.

## What Gets Generated

Running the example produces reusable MATLAB functions:

| Generated file | Signature | Use case |
|----------------|-----------|----------|
| `predictTerminalVoltage.m` | `V_pred = predictTerminalVoltage(z, V1, V2, I, R0_mid, lowFactor, highFactor)` | Terminal-voltage prediction using piecewise OCV and SOC-dependent resistance |
| `batteryOutputJacobian.m` | `C_out = batteryOutputJacobian(z, I, R0_mid, lowFactor, highFactor)` | Measurement Jacobian for EKF covariance and gain update |
| `batteryStateUpdate.m` | `x_next = batteryStateUpdate(z, V1, V2, I)` | Exact discrete-time prediction step for the nominal cell |

C-code expressions are also printed with `ccode()` for the impedance model and state update. Treat those snippets as an optional export path for third-party firmware, calibration tools, or implementation review. For Embedded Coder&reg;, use the generated MATLAB functions in a Simulink MATLAB Function block and generate code from the Simulink model.

## Downstream Workflow Connections

The generated functions and symbolic expressions are intended as building blocks for engineering workflows:

### EIS Parameter Identification
The impedance expression `Z_cell` is converted to a MATLAB function handle and fit to synthetic EIS data. In a calibration workflow, the same function can fit measured impedance spectra to recover `R0`, `R1`, `C1`, `R2`, and `C2`.

### Simulink / Embedded Coder Observer Implementation
`predictTerminalVoltage.m`, `batteryOutputJacobian.m`, and `batteryStateUpdate.m` provide the compact computational core for a Simulink MATLAB Function block. The observer gain or EKF covariance update remains a control-design choice, but the model equations and Jacobian come from the symbolic derivation.

### Simscape Battery Plant Validation
A high-fidelity Simscape Battery cell or pack model can serve as the plant while a Simulink MATLAB Function block calls the generated 3-state Thevenin observer functions. Feed the plant current and terminal voltage into the observer, then compare predicted voltage and estimated SOC against plant outputs across drive cycles. The validation question becomes parameter accuracy and operating-envelope coverage, not whether the observer equations were copied correctly.

### Calibration and Margin Analysis
The symbolic sensitivities quantify which parameter uncertainties most affect terminal voltage or SOC drift. This supports HPPC test planning, SOH extensions, thermal-resistance compensation, and capacity-fade monitoring.

## Quick Start

### Requirements

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2025a or later for plain-text Live Script support
- [Symbolic Math Toolbox](https://www.mathworks.com/products/symbolic.html)
- Optional downstream tools: Simulink, Embedded Coder, Simscape Battery

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`EVBatterySOCEstimation.m`** as a Live Script
3. Run section by section, or run all

The generated functions (`predictTerminalVoltage.m`, `batteryOutputJacobian.m`, `batteryStateUpdate.m`) are written to the working directory at runtime and ignored by source control.

## Files

| File | Description |
|------|-------------|
| `EVBatterySOCEstimation.m` | Main example (Live Script). Full workflow from Thevenin derivation through observer handoff and EIS fitting. |
| `predictTerminalVoltage.m` | Generated at runtime. Terminal-voltage prediction with piecewise OCV and SOC-dependent resistance. |
| `batteryOutputJacobian.m` | Generated at runtime. Output Jacobian for EKF/Luenberger observer workflows. |
| `batteryStateUpdate.m` | Generated at runtime. Exact ZOH state update for the nominal cell. |

Copyright 2026 The MathWorks, Inc.
