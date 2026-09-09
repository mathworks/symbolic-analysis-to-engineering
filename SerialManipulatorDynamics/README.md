# Serial Manipulator Kinematics and Dynamics

Serial manipulators are inherently symbolic objects. The homogeneous transformation matrices are parameterized by joint angles, the velocity mapping is literally "the Jacobian" in the calculus sense, and the Lagrangian dynamics produce torque equations as explicit functions of configuration. This example derives the complete kinematic and dynamic model of a 2-DOF planar elbow manipulator in closed form, implements a computed-torque controller from the symbolic decomposition, and checks the generated functions in simulation.

The key insight that symbolic math delivers: the equations of motion decompose exactly into $M(q)\ddot{q} + C(q,\dot{q})\dot{q} + G(q) = \tau$, where each matrix is an explicit function of link parameters and configuration. A computed-torque controller exploits this decomposition to cancel all nonlinear terms -- achieving linear error dynamics regardless of configuration or speed. The symbolic form makes this possible without lookup tables, polynomial fits, or online estimation.

## What This Example Covers

| Phase | What It Does | Key SMT Functions |
|---|---|---|
| 1 -- DH Forward Kinematics | Homogeneous transforms, end-effector position, symbolic forward kinematics | `simplify` |
| 2 -- The Jacobian | Geometric Jacobian, term-by-term structure, singularity analysis, velocity mapping | `jacobian`, `det`, `solve` |
| 3 -- Lagrangian Dynamics | Kinetic/potential energy, inertia matrix, Christoffel symbols, Coriolis matrix, gravity vector | `jacobian`, `diff`, `simplify` |
| 4 -- Analytical Sensitivities | Torque sensitivity, kinematic manipulability, dynamic conditioning | `diff`, `det` |
| 5 -- Computed-Torque Controller | Control law derivation, closed-loop error dynamics, gain selection | `dsolve` |
| 6 -- Code Generation | Deployable M, C, G, Jacobian functions, and Simscape equation strings | `matlabFunction`, `simscapeEquation` |
| 7 -- Simulation | 1 kHz computed-torque self-consistency check using generated functions | Generated functions in loop |
| 8 -- Downstream Workflows | Robotics System Toolbox cross-check, deployment notes, parameter sensitivity | N/A |

## Robot Configuration

Representative 2-DOF planar elbow manipulator in the vertical plane:
- Link 1: 0.5 m, 5.0 kg (upper arm, includes joint 2 motor)
- Link 2: 0.4 m, 3.0 kg (forearm + end-effector)
- CoM: midpoint of each link (Lc1 = 0.25 m, Lc2 = 0.20 m)
- Inertia: uniform rod approximation
- Controller: computed-torque with critically damped error dynamics (omega_n = 10 rad/s)

## Quick Start

### Requirements

- [MATLAB&reg;](https://www.mathworks.com/products/matlab.html) R2025a or later
- [Symbolic Math Toolbox&trade;](https://www.mathworks.com/products/symbolic.html)
- [Robotics System Toolbox&trade;](https://www.mathworks.com/products/robotics.html)

### Running the Example

Open `SerialManipulatorDynamics.m` in the MATLAB Live Editor and run all sections. The script generates:
- `armInertiaMatrix.m` -- M(q) evaluator
- `armCoriolisMatrix.m` -- C(q, dq) evaluator
- `armGravityTorque.m` -- G(q) evaluator
- `armJacobian.m` -- J(q) evaluator

## Applications

The symbolic manipulator dynamics demonstrated here are directly applicable to:

| Application | Extension |
|-------------|-----------|
| **6-DOF industrial arm** | Same DH workflow with 6 links; expressions are longer but the pattern is identical |
| **Payload estimation** | Invert the gravity torque formula: measure tau at static config, solve for unknown m2 |
| **Impedance control** | Replace computed-torque with tau = M*a_d + C*dq + G + K_imp*e + D_imp*de |
| **Flexible-joint robots** | Add motor-side states (rotor inertia, gear ratio) to the Lagrangian |
| **Collision detection** | Compare measured torque to M*ddq + C*dq + G; residual indicates external force |

## Downstream Deployment Path

This example stops at generated MATLAB functions and Simscape equation strings. It does not build a Simulink model, write a Simscape component file, or generate embedded code; those are natural next steps for a larger workflow.

```
Symbolic M(q), C(q,dq), G(q), J(q) (this example)
    |
    +--> matlabFunction: generated M, C, G, J evaluators
    |       |
    |       +--> Simulink: call generated functions from MATLAB Function blocks
    |               |
    |               +--> Embedded Coder: generate controller C code from a Simulink workflow
    |
    +--> Simscape language: use equation strings when authoring a custom component
    |
    +--> Robotics System Toolbox: rigidBodyTree cross-check, planning, visualization
```

Copyright 2026 The MathWorks, Inc.