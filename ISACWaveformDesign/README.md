# Symbolic Waveform Design for Integrated Sensing and Communications (ISAC)

OFDM ISAC waveform design for a monostatic SISO radar-communications system operating at 3.5 GHz with 30.72 MHz bandwidth (1024 subcarriers, 30 kHz spacing). The pilot fraction *alpha* - the allocation of subcarriers between Zadoff-Chu radar pilots and QAM data - controls the sensing-vs-throughput tradeoff.

This example shows how closed-form symbolic analysis improves an engineering workflow before simulation. It derives the cross-ambiguity function, Cramer-Rao bound on range estimation, and Shannon throughput as expressions in *alpha* and the waveform parameters. Those expressions are evaluated across the design space, then two operating points are carried into waveform generation, spectral analysis, range-Doppler processing, and pilot-based equalization with EVM measurement.

## Why Symbolic Analysis Matters

- One derivation gives the full sensing-vs-throughput trade space, instead of one simulation result at a time.
- The closed-form expressions expose which parameters control resolution, estimation accuracy, and data rate.
- `matlabFunction` turns the symbolic CRB and throughput into fast numeric evaluators for Pareto exploration.
- The numerical waveform sections validate the assumptions and show how the design choice affects PSD, range-Doppler response, and EVM.

## Example Outline

### 1. OFDM Signal Model
Symbolic declaration of the signal model: *N* subcarriers, pilot fraction *alpha*, subcarrier spacing *Delta_f*, and frame structure with *M* OFDM symbols.

### 2. Radar Performance: Cross-Ambiguity Function
Derive the frequency-domain and time-domain ambiguity functions as closed-form Dirichlet kernels via `symsum` and `simplify`. The resulting expressions give range and Doppler resolution as explicit functions of the design parameters.

### 3. Communications Performance
Shannon throughput and spectral efficiency as symbolic functions of *alpha*, using the same signal model.

### 4. The ISAC Tradeoff: Pareto Frontier
Derive the Cramer-Rao bound on range estimation from the radar SNR and pilot RMS bandwidth using `subs` and `simplify`. The CRB uses the already-integrated radar SNR and the pilot spacing `(N/K)*Delta_f`, so the range variance scales primarily with total radar SNR for fixed occupied bandwidth. Convert the CRB and throughput to callable function handles with `matlabFunction`, evaluate a 5G-style design point, and plot the Pareto frontier.

### 5. Pilot Sequence Design with Number-Theoretic Constraints
Zadoff-Chu sequences require prime length and a coprime root index. Given a desired pilot count *K = alpha * N*, find the nearest valid length with `prevprime` and `nextprime`, verify the root with `gcd`, and confirm ideal periodic autocorrelation both symbolically (`symsum`) and numerically (`zadoffChuSeq` from Communications Toolbox&trade;).

### 6. Convert Symbolic Design to Numerical Simulation
Select two operating points from the symbolic Pareto view: sensing-heavy (*alpha* = 0.75) and comms-heavy (*alpha* = 0.25). Extract scalar parameters via `double`, then generate OFDM ISAC waveforms using `ofdmmod`, `qammod`, and `zadoffChuSeq`, with per-symbol pseudo-random pilot scrambling to flatten the power spectrum.

### 7. Spectral Verification
Measure the power spectral density of both waveforms with `pwelch` and `hamming` (Signal Processing Toolbox&trade;) and overlay the symbolically predicted occupied bandwidth.

### 8. Range-Doppler Processing
Simulate a single target (150 m, 30 m/s). The OFDM radar processor divides the received pilot subcarriers by the known transmitted pilots, interpolates the estimates onto the uniform OFDM subcarrier grid, then applies IFFT (range) and shifted FFT (Doppler). The resulting range-Doppler maps are shown with the symbolically predicted resolution cell overlaid.

### 9. EVM Measurement for Communications Quality
The pilot subcarriers also serve as channel estimates for the communications receiver. Per-symbol channel estimation on the pilots is interpolated to the data subcarriers (`interp1`) and used to equalize the Doppler-induced phase rotation. EVM is measured with `comm.EVM` at both operating points.

## Quick Start

### Requirements

- [MATLAB&reg;](https://www.mathworks.com/products/matlab.html) R2024b or later
- [Symbolic Math Toolbox&trade;](https://www.mathworks.com/products/symbolic.html)
- [Communications Toolbox](https://www.mathworks.com/products/communications.html)
- [Signal Processing Toolbox](https://www.mathworks.com/products/signal.html)

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`ISACWaveformDesign.m`** as a Live Script
3. Run section by section, or run all

## Files

| File | Description |
|------|-------------|
| `ISACWaveformDesign.m` | Main example (Live Script). Full workflow from symbolic derivation through waveform validation. |

## Related

For a full system-level MIMO-OFDM ISAC simulation building on these concepts, see [Integrated Sensing and Communication II: Communication-Centric Approach Using MIMO-OFDM](https://www.mathworks.com/help/phased/ug/integrated-sensing-and-communication-2-communication-centric-approach-using-mimo-ofdm.html).

Copyright 2026 The MathWorks, Inc.
