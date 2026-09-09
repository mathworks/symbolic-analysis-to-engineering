# Symbolic Knife-Edge Diffraction for Radar Link-Budget and Detection Workflows

This example derives, deploys, and validates a closed-form knife-edge diffraction model for a radar signal grazing a terrain ridge. The starting point is the Fresnel-Kirchhoff diffraction integral; Symbolic Math Toolbox&trade; reduces the tail integrals to Fresnel sine and cosine terms, then `matlabFunction` turns the result into reusable numeric kernels.

The core idea is that symbolic work should not stop at a plot. The derived diffraction expression is reused in a ridge geometry function, a two-way radar link budget, a matched-filter detection example, exact sensitivity analysis, and a small physics-aware target classification workflow.

The same workflow applies to terrain-masked surveillance radars, over-the-horizon feasibility studies, path-loss margin analysis, and radar coverage tools that need fast repeated evaluation across altitude, range, or terrain uncertainty.

## Example Outline

### 1. Fresnel-Kirchhoff Diffraction Integral
Symbolic derivation begins with the complex knife-edge field coefficient:

$$F(\nu) = \frac{1+j}{2}\int_{\nu}^{\infty}\exp\left(-j\frac{\pi t^2}{2}\right)dt$$

where positive normalized clearance $\nu$ means the obstruction protrudes into the line of sight.

### 2. Closed-Form Diffraction Gain and Loss
The symbolic cosine and sine tail integrals reduce to `1/2 - fresnelc(nu)` and `1/2 - fresnels(nu)`. The script derives linear power gain, positive diffraction loss in dB, and the exact derivative of loss with respect to $\nu$.

- `int` - evaluates the Fresnel tail integrals symbolically
- `simplify` - reduces gain, loss, and sensitivity expressions
- `diff` - produces exact loss sensitivity

### 3. Code Generation: Deployable Diffraction Kernels
`matlabFunction` generates reusable functions for the diffraction kernel and ridge geometry. The shipped `radarLinkBudget.m` helper then integrates the generated diffraction loss into a two-way monostatic radar equation.

- `matlabFunction` - generates `knifeEdgeDiffractionKernels.m` and `ridgeFresnelGeometry.m`
- `radarLinkBudget.m` - shipped helper that consumes the generated diffraction kernel

### 4. Reference Scenario: S-Band Radar Behind a Ridge
The reference case is a 3 GHz ground radar observing a small aircraft whose line of sight grazes a mountain ridge. The link-budget printout reports one-way diffraction loss and the two-way loss applied inside the monostatic SNR calculation separately.

### 5. Altitude Sweep: Diffraction Loss to Detection Margin
The generated functions evaluate diffraction loss and SNR over a target-altitude sweep. This shows how a first-principles expression becomes a fast coverage and margin analysis tool.

### 6. Matched-Filter Detection Using the Derived SNR
The nominal link-budget SNR sets the echo amplitude in a synthetic radar return. A matched filter recovers the target range, showing how the symbolic propagation result feeds signal-processing behavior.

### 7. Sensitivity Analysis: Ridge Clearance
The script evaluates exact $\partial L/\partial \nu$ and maps it to $\partial L/\partial h$, where $h$ is ridge clearance relative to line of sight. A 32-digit `vpa` finite-difference check verifies the analytic sensitivity. The altitude sweep shows both the exact single-frequency Fresnel fringes and a smoothed engineering trend that better represents finite-bandwidth radar, rough terrain edges, and atmospheric smear.

- `diff` - exact derivative of diffraction loss
- `vpa` - high-precision verification against finite difference

### 8. Classification Features from the Same Physics
A compact signature library uses SNR, diffraction loss, altitude, and radar cross section as features. The classifier is deliberately simple; the important point is that the derived propagation model is reused as an upstream feature generator.

### 9. Operational Sweep: Detection Altitude Versus Radar Power
A final trade study estimates the minimum target altitude needed to maintain a 10 dB detection margin as transmitter power changes. This is the symbolic-to-engineering payoff: one generated kernel supports repeated design-space evaluation.

## What Gets Generated

Running the example produces reusable MATLAB&reg; files from symbolic expressions:

| Generated file | Signature | Use case |
|----------------|-----------|----------|
| `knifeEdgeDiffractionKernels.m` | `[gainLinear, lossDb, dLossDnu] = knifeEdgeDiffractionKernels(nu)` | Diffraction gain, loss, and sensitivity versus normalized clearance |
| `ridgeFresnelGeometry.m` | `[nu, h, F1] = ridgeFresnelGeometry(targetAlt, radarAlt, ridgeAlt, d1, d2, lambda)` | Convert ridge/target geometry to Fresnel clearance |

The generated files are written to the working directory at runtime and are ignored by the local `.gitignore`.

## Downstream Workflow Connections

### Radar Coverage and Link-Budget Tools
`ridgeFresnelGeometry.m` and `knifeEdgeDiffractionKernels.m` can be called from coverage-analysis code that sweeps target altitude, range, and terrain height. The example demonstrates this directly with altitude-to-SNR curves and detection-margin thresholds.

### Signal Processing Workflows
`radarLinkBudget.m` provides the SNR used to scale a synthetic received pulse. That pulse is then processed with a matched filter, connecting the symbolic propagation model to range extraction and detection behavior.

### Sensitivity and Margin Analysis
The exact derivative `dLossDnu` supports clearance and terrain-uncertainty studies without finite-difference noise. This is useful when terrain elevation, platform altitude, or refraction assumptions are uncertain near a grazing path.

### Classification and Analytics
The derived diffraction loss becomes a feature in the target classification section. This pattern is useful when analytics pipelines need physically meaningful features rather than purely synthetic or black-box inputs.

## Quick Start

### Requirements

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2024b or later
- [Symbolic Math Toolbox](https://www.mathworks.com/products/symbolic.html)
- [Signal Processing Toolbox&trade;](https://www.mathworks.com/products/signal.html)

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`RadarKnifeEdgeDiffraction.m`** as a Live Script
3. Run section by section, or run all

The generated functions (`knifeEdgeDiffractionKernels.m`, `ridgeFresnelGeometry.m`) are written to the working directory at runtime. The link-budget helper `radarLinkBudget.m` is shipped as normal source.

## Files

| File | Description |
|------|-------------|
| `RadarKnifeEdgeDiffraction.m` | Main example (Live Script). Full workflow from symbolic diffraction derivation through radar detection and trade studies. |
| `knifeEdgeDiffractionKernels.m` | Generated at runtime. Diffraction gain, loss, and loss sensitivity. |
| `ridgeFresnelGeometry.m` | Generated at runtime. Ridge geometry to normalized Fresnel clearance. |
| `radarLinkBudget.m` | Shipped helper. Monostatic radar link budget with diffraction loss from the generated kernel. |

Copyright 2026 The MathWorks, Inc.