# From First Principles to Engineering Workflows

[![View on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/)
[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/)

Application examples that show how to get started with [Symbolic Math Toolbox&trade;](https://www.mathworks.com/products/symbolic.html) for first-principles analysis and to re-use this work in downstream numerical workflows. Start by deriving closed-form models, perform parameter sweeps and linearize, then generate MATLAB&reg; functions, Simulink&reg; function blocks, or Simscape&trade; equations for use in engineering workflows.

Each example is self-contained and runs as a MATLAB Live Script.

## Examples

| Example | Domain | Description | Other Toolboxes |
|---------|--------|-------------|-----------------|
| [SpacecraftAttitudeSlew](SpacecraftAttitudeSlew/) | Aerospace | Spacecraft slew maneuver planning — Euler's equations to eigenaxis dynamics, bang-bang and trapezoidal profiles via `dsolve`, parametric slew time, sensitivity to inertia/actuator degradation with `vpa` verification, and multi-target scheduling | [Aerospace Toolbox&trade;](https://www.mathworks.com/products/aerospace-toolbox.html) |
| [DCMotorSpeedAdaptive](DCMotorSpeedAdaptive/) | Automotive | Adaptive DC motor speed control — symbolic state feedback gains as functions of load inertia, from 4-state drivetrain model through pole placement to Simulink deployment | [Control System Toolbox&trade;](https://www.mathworks.com/products/control.html), [Simulink](https://www.mathworks.com/products/simulink.html) |
| [BlackScholesGreeks](BlackScholesGreeks/) | Financial | Black-Scholes Greeks from first principles — PDE verification, exact first- and second-order Greeks, near-ATM Taylor approximations, digital option limits, multi-asset cross-Greeks via Jacobian, and Monte Carlo with exact sensitivities | [Financial Toolbox&trade;](https://www.mathworks.com/products/finance.html) |
| [ISACWaveformDesign](ISACWaveformDesign/) | Wireless | OFDM ISAC waveform design — cross-ambiguity function, Cramér-Rao bound, and Shannon throughput as closed-form functions of pilot fraction, with Zadoff-Chu pilot sequence design | [Communications Toolbox&trade;](https://www.mathworks.com/products/communications.html), [Signal Processing Toolbox&trade;](https://www.mathworks.com/products/signal.html) |

## The Common Pattern

Each example follows the same workflow:

1. **Model from first principles** — declare physical parameters as symbolic variables and derive the governing equations
2. **Analyze symbolically** — simplify, solve, differentiate, or integrate to obtain closed-form results (transfer functions, sensitivities, design equations, stability conditions)
3. **Export code and models** — substitute known numeric parameters and generate executable MATLAB functions or C code
4. **Validate numerically** — the generated functions are used directly in simulations, Monte Carlo engines, Simulink models, etc

The symbolic derivation and the deployed code stay in sync, so changing an assumption upstream can be automatically propagated downstream.

## Getting Started

### Requirements

- MATLAB R2024b or later (R2025a+ for some examples)
- Symbolic Math Toolbox (all examples)
- Additional toolboxes as listed in the table above and in each example's README

### Running an Example

1. Open MATLAB and navigate to the example's directory
2. Open the `.m` file as a Live Script
3. Run section by section, or run all — each example is self-contained

Some examples generate additional `.m` files at runtime via `matlabFunction`. These are written to the example's directory and are gitignored.

## License

See [LICENSE](LICENSE) for details. Copyright (c) 2026, The MathWorks, Inc.
