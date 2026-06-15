# Adaptive DC Motor Speed Control with Drivetrain Compliance

This example demonstrates how Symbolic Math Toolbox&trade; enables physics-aware controller design for automotive applications. A DC motor drives a load through a flexible shaft, creating a 4-state drivetrain model whose torsional resonance depends on the reflected load inertia $J_L$.

The load inertia varies with operating conditions: full traction with a heavy vehicle gives $J_L \approx 0.5$ kg.m^2, lost traction can drop $J_L$ to about 0.01, and different platforms such as sedans, SUVs, and trucks have different inertia ranges. When $J_L$ changes, the resonance frequency shifts; a controller tuned for one inertia can degrade or excite the resonance at another.

By keeping $J_L$ symbolic through the control design workflow, the state feedback gains become simulatable functions $K(J_L)$ instead of fixed constants. The controller adapts by changing the load-inertia input, not by re-tuning the pole placement design.

## Example Outline

### 1. Symbolic System Modeling
Symbolic declaration of a four-state motor-shaft-load drivetrain: motor speed $\omega_m$, armature current $i$, shaft twist angle $\Delta\theta$, and load speed $\omega_L$. The input is armature voltage $V$ and the output is load speed $\omega_L$.

The flexible shaft coupling uses stiffness $K_s$ and damping $C_s$, which create the torsional resonance that shifts with $J_L$.

- `syms` - declare physical parameters symbolically
- Symbolic state-space matrices - encode motor, electrical, shaft, and load dynamics

### 2. Open-Loop Dynamics: How Load Inertia Affects the Plant
Known motor and shaft constants are substituted while $J_L$ remains symbolic. The example sweeps $J_L$ from 0.01 to 0.5 kg.m^2 and shows two effects: open-loop poles migrate in the complex plane, and the torsional resonance peak shifts in the frequency response from $V$ to $\omega_L$.

- `subs` - selectively substitute fixed motor and shaft parameters
- `eig` - compute pole migration across the inertia range
- `ss`, `bode` - visualize the load-speed frequency response

### 3. State Feedback Gains as Functions of $J_L$
The control law is $u = -Kx + \bar{N}r$. Desired closed-loop poles are set at -100, -15, and $-8 \pm 8i$, giving a fast electrical mode, a moderate real pole, and a dominant complex pair with about 0.5 seconds settling.

Because the system matrix contains symbolic $J_L$, solving the pole placement equations produces $K = [k_1, k_2, k_3, k_4]$ as functions of $J_L$. The precompensator $\bar{N}(J_L)$ is computed for zero steady-state load-speed error, yielding the complete adaptive law $u = -K(J_L)x + \bar{N}(J_L)r$.

- `det` - form the controllability determinant and characteristic equation
- `solve` - compute symbolic pole placement gains
- `simplify`, `subs` - reduce gains after substituting fixed physical constants

### 4. Verification: Desired Poles Are Achieved for Any $J_L$
The closed-loop matrix $A - BK(J_L)$ is evaluated at $J_L = 0.01$, 0.05, 0.2, and 0.5. The computed eigenvalues match the desired pole set for each case, and step responses show consistent settling behavior across the full inertia range.

- `eig` - verify closed-loop poles after substituting each inertia
- `step` - compare load-speed tracking responses

### 5. Fixed vs. Adaptive Gains
A fixed-gain controller designed for SUV full traction ($J_L = 0.2$) is applied after traction loss ($J_L = 0.02$). The fixed controller fails to suppress the shifted torsional resonance, while gains evaluated at the actual inertia maintain the desired response.

The live script also notes that real actuator voltage limits, such as a 48 V armature supply, would make resonance-driven voltage swings more damaging in production unless voltage limiting and anti-windup are included.

### 6. Code Generation: Simulatable Controller Functions
Convert the symbolic gain and reference-scaling expressions into optimized MATLAB functions. These functions take $J_L$ as input and return the correct controller parameters for simulation.

- `matlabFunction` - generates `controllerGains.m` and `referenceScaling.m`
- `ccode` - emits C code for the symbolic gain expressions

### 7. Simulink Integration
The generated functions can be called directly from MATLAB&reg; Function blocks in Simulink&reg;. The estimated load inertia can come from a lookup table, online estimator, or traction control module.

```text
                   J_L_est (from estimator, lookup, or traction module)
                     |            |               |
                     v            v               v
r -----> [Nbar(JL)] -->(+)----> u ---> [Plant(JL)] ----> y
                       ^(-)               |
                       |                  v
                       +---- [K(JL)] <--- x (state feedback)
```

`buildSimulinkModel.m` creates a working model for a traction-loss scenario where $J_L$ switches from 0.2 to 0.02 at $t = 5$ seconds.

## What Gets Generated

Running the example produces deployable MATLAB functions:

| Generated file | Signature | Use case |
|----------------|-----------|----------|
| `controllerGains.m` | `K = controllerGains(J_L)` | 1x4 state feedback gain vector for the current load inertia |
| `referenceScaling.m` | `Nbar = referenceScaling(J_L)` | Reference precompensator for zero steady-state load-speed error |

C code equivalents for the gain expressions are available via `ccode()`.

## Quick Start

### Requirements

- [MATLAB](https://www.mathworks.com/products/matlab.html) R2024b or later
- [Symbolic Math Toolbox](https://www.mathworks.com/products/symbolic.html)
- [Control System Toolbox&trade;](https://www.mathworks.com/products/control.html)
- [Simulink](https://www.mathworks.com/products/simulink.html) (for the generated integration model)

### Running the Example

1. Open MATLAB and navigate to this directory
2. Open **`DCMotorSpeedAdaptive.m`** as a Live Script
3. Run section by section, or run all - the example is self-contained
4. Run **`buildSimulinkModel.m`** to create the Simulink traction-loss model

The generated functions (`controllerGains.m`, `referenceScaling.m`) are written to the working directory at runtime. The Simulink model (`DCMotorSpeedAdaptiveModel.slx`) is created by `buildSimulinkModel.m`.

## Files

| File | Description |
|------|-------------|
| `DCMotorSpeedAdaptive.m` | Main example (Live Script). Full workflow from symbolic drivetrain modeling through adaptive gain generation and verification. |
| `buildSimulinkModel.m` | Programmatically creates the Simulink model that uses the generated functions in a traction-loss scenario. |
| `controllerGains.m` | Generated at runtime. State feedback gains as a function of load inertia. |
| `referenceScaling.m` | Generated at runtime. Reference scaling as a function of load inertia. |
| `DCMotorSpeedAdaptiveModel.slx` | Generated by `buildSimulinkModel.m`. Simulink model demonstrating runtime-adaptive control. |
