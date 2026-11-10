# Symbolic Channel Modeling for Underwater Acoustic Communications

This example derives, analyzes, and validates the physical-layer model for an underwater acoustic (UWA) communication link between an autonomous underwater vehicle (AUV) and a surface buoy: a 12 km patrol range at 20 kHz through Rayleigh fading with elevated ambient-noise density.

Standard UWA channel design relies on numeric simulation sweeps to evaluate coding strategies. The symbolic approach builds the channel model in closed form, so design decisions such as "is rate 3/4 LDPC viable at this SNR?" can be answered analytically before running any simulation. The symbolic expressions are then converted to MATLAB&reg; function handles via `matlabFunction` and used directly in the Communications Toolbox transmit/receive chain, eliminating the gap between analysis and simulation.

The same workflow applies to other physical-layer design problems where closed-form channel models feed into system simulation: sonar link budgets, RF propagation over terrain, optical free-space links, or any scenario where you need parametric design equations before committing to Monte Carlo.

## Example Outline

### 1. Symbolic Modeling of the Underwater Channel

Symbolic declaration of the channel physics: frequency-dependent Thorp absorption, geometric spreading, SNR link budget, Nakagami-m fading SER, AWGN capacity bound, and Rayleigh fading capacity derived as an expectation over fade power. All quantities remain symbolic until Phase 2.

- `syms` - declare physical parameters with assumptions (`positive`, `real`)
- `subs`, `simplify` - specialize the general Nakagami SER to Rayleigh/QPSK
- `isolate` - solve the AWGN capacity equation for SNR and bandwidth
- `int` - derive Rayleigh capacity as a closed-form fading expectation
- `expint` - express the Rayleigh capacity in a compact numeric-handoff form
- `gradient` - closed-form SER sensitivity; normalized to elasticity (% change in SER per % change in SNR)
- `fmesh` - 3-D SER surface over frequency and distance, with the operating point annotated to expose the failure region
- `matlabFunction` - convert symbolic expressions to numeric function handles

### Handoff: `matlabFunction` Bridge

Four symbolic expressions are converted to callable MATLAB functions that drive the downstream simulation:

| Handle | Source expression | Used for |
|--------|-------------------|----------|
| `SER_nakagami_fn(gamma_s, m_nak, M_order)` | General Nakagami SER | Evaluating uncoded SER at any operating point |
| `alpha_fn(f)` | Thorp absorption coefficient | Per-frequency absorption lookup |
| `TL_fn(f, d, k_spread)` | Transmission loss | Computing numeric SNR for the Communications Toolbox chain |
| `maxRate_rayleigh_fn(gamma_s, M_order)` | Rayleigh capacity code-rate bound | Selecting a viable LDPC rate before simulation |

### 2. Communications Simulation (Rate 3/4 LDPC)

Full transmit/receive chain using Communications Toolbox: CRC, DVB-S.2 LDPC encoding, QPSK modulation, Rayleigh fading channel (Nakagami $m = 1$), zero-forcing equalization, soft-decision LDPC decoding. The SNR is computed by calling `TL_fn` and applying the symbolic noise-bandwidth term, so the physics model and the simulation share a single source of truth.

- `crcConfig`, `crcGenerate` - CRC-16 error detection
- `dvbsLDPCPCM`, `ldpcEncoderConfig`, `ldpcDecoderConfig` - DVB-S.2 LDPC code setup
- `ldpcEncode`, `ldpcDecode` - channel coding
- `pskmod`, `pskdemod` - QPSK modulation with soft LLR output
- `awgn` - explicit unit-power AWGN with captured noise variance for LLR demodulation
- `gamrnd` - Nakagami-m fading channel realization (Statistics and Machine Learning Toolbox)

### 3. Diagnosis

Monte Carlo BER variance estimation confirms the link is unreliable. The symbolic capacity analysis from Phase 1 is revisited: the maximum achievable code rate at the operating SNR is computed by substituting into the Rayleigh capacity expression, confirming that rate 3/4 exceeds the fading-channel limit.

- `datasample` - bootstrap BER sampling (Statistics and Machine Learning Toolbox)

### 4. Strengthen the Comms Chain

The symbolic capacity constraint prescribes a code rate well below the limit. The comms chain is rebuilt with a DVB-S.2 rate-1/4 LDPC code. Same Rayleigh channel, same distance, same SNR - only the coding changes.

- `maxRate_rayleigh_fn` - evaluate the symbolic max-rate expression at the numeric operating point
- `ldpcEncoderConfig(dvbsLDPCPCM('1/4'))` - configure the stronger low-rate LDPC code

The final plot overlays the symbolic uncoded SER curve with the simulated coded BER from both configurations, showing the coding gain achieved and confirming that the symbolic analysis correctly guided the design decision.

## Quick Start

### Requirements

- [MATLAB&reg;](https://www.mathworks.com/products/matlab.html) R2025a or later
- [Symbolic Math Toolbox&trade;](https://www.mathworks.com/products/symbolic.html)
- [Communications Toolbox&trade;](https://www.mathworks.com/products/communications.html)
- [Statistics and Machine Learning Toolbox&trade;](https://www.mathworks.com/products/statistics.html)

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`UnderwaterAcousticChannel.m`** as a Live Script
3. Run section by section, or run all - the example is self-contained

## Files

| File | Description |
|------|-------------|
| `UnderwaterAcousticChannel.m` | Main example (Live Script). Full workflow from symbolic channel derivation through simulation validation. |

Copyright 2026 The MathWorks, Inc.