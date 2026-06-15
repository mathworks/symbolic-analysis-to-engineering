# Symbolic Waveform Design for Integrated Sensing and Communications (ISAC)

OFDM ISAC waveform design for a monostatic SISO radar-communications system operating at 3.5 GHz with 30.72 MHz bandwidth (1024 subcarriers, 30 kHz spacing). The pilot fraction *alpha* - the allocation of subcarriers between Zadoff-Chu radar pilots and QAM data - controls the sensing-vs-throughput tradeoff.

The symbolic analysis derives the cross-ambiguity function, Cramér-Rao bound on range estimation, and Shannon throughput as closed-form expressions in *alpha* and the waveform parameters. These are converted to function handles via `matlabFunction`, producing a Pareto frontier that maps the full design space without Monte Carlo sweeps or repeated simulation. Scalar design parameters (ZC sequence length, root index, subcarrier allocations) are extracted via `double` at two operating points and fed directly into waveform generation, spectral analysis, range-Doppler processing, and pilot-based equalization with EVM measurement, validating the symbolic predictions against the numerical results.

## Example Outline

### 1. OFDM Signal Model
Symbolic declaration of the signal model: *N* subcarriers, pilot fraction *alpha*, subcarrier spacing *Delta_f*, frame structure with *M* OFDM symbols.

### 2. Radar Performance: Cross-Ambiguity Function
Derive the frequency-domain and time-domain ambiguity functions as closed-form Dirichlet kernels via `symsum` and `simplify`. The resulting expressions give range and Doppler resolution as explicit functions of the design parameters.

### 3. Communications Performance
Shannon throughput and spectral efficiency as symbolic functions of *alpha*, using the same signal model.

### 4. The ISAC Tradeoff: Pareto Frontier
Derive the Cramér-Rao bound on range estimation from the radar SNR expression (`diff`, `simplify`). Both the CRB and the throughput are now closed-form functions of *alpha*. Convert them to callable function handles with `matlabFunction` and `subs`, evaluate at a concrete design point (1024 subcarriers, 30 kHz spacing, 3.5 GHz carrier), and plot the Pareto frontier.

### 5. Pilot Sequence Design with Number-Theoretic Constraints
Zadoff-Chu sequences require prime length and a coprime root index. Given a desired pilot count *K = alpha * N*, find the nearest valid length with `prevprime` and `nextprime`, verify the root with `gcd`, and confirm ideal periodic autocorrelation both symbolically (`symsum`) and numerically (`zadoffChuSeq` from Communications Toolbox).

### 6. Convert Symbolic Design to Numerical Simulation
Extract scalar parameters via `double` and function handles via `matlabFunction` at two operating points: sensing-heavy (*alpha* = 0.75) and comms-heavy (*alpha* = 0.25). Generate OFDM ISAC waveforms using `ofdmmod`, `qammod`, and `zadoffChuSeq` (Communications Toolbox), with per-symbol pseudo-random pilot scrambling to flatten the power spectrum.

### 7. Spectral Verification
Measure the power spectral density of both waveforms with `pwelch` and `hamming` (Signal Processing Toolbox) and overlay the symbolically-predicted occupied bandwidth.

### 8. Range-Doppler Processing
Simulate a single target (150 m, 30 m/s). The OFDM radar processor divides the received pilot subcarriers by the known transmitted pilots, then applies IFFT (range) and FFT (Doppler). The resulting range-Doppler maps are shown with the symbolic resolution cell overlaid.

### 9. EVM Measurement for Communications Quality
The pilot subcarriers also serve as channel estimates for the communications receiver. Per-symbol channel estimation on the pilots is interpolated to the data subcarriers (`interp1`) and used to equalize the Doppler-induced phase rotation. EVM is measured with `comm.EVM` (Communications Toolbox) at both operating points: the sensing-heavy design equalizes better because the denser pilot grid produces more accurate interpolation.

## Requirements

- MATLAB R2024b or later
- Symbolic Math Toolbox
- Communications Toolbox
- Signal Processing Toolbox

## Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`ISACWaveformDesign.m`** as a Live Script
3. Run section by section, or run all — the example is self-contained

## Files

| File | Description |
|------|-------------|
| `ISACWaveformDesign.m` | Main example (Live Script). Full workflow from symbolic derivation through waveform validation. |

## Related

For a full system-level MIMO-OFDM ISAC simulation building on these concepts, see [Integrated Sensing and Communication II: Communication-Centric Approach Using MIMO-OFDM](https://www.mathworks.com/help/phased/ug/integrated-sensing-and-communication-2-communication-centric-approach-using-mimo-ofdm.html).
