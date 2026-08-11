%[text] # Adaptive DC Motor Speed Control with Drivetrain Compliance
%[text] Design physics-aware speed control for a DC motor driving a load through a flexible shaft. Keeping the reflected load inertia $J\_L$ symbolic exposes how drivetrain compliance shifts the torsional resonance, then produces state-feedback gains $K(J\_L)$ that adapt across traction and vehicle-load conditions without re-tuning.
%[text] **Workflow:** derive the symbolic 4-state motor-shaft-load model → substitute motor and shaft constants while sweeping $J\_L$ → analyze open-loop pole migration and resonance shift → place closed-loop poles symbolically for $K(J\_L)$ → generate adaptive gain and reference-scaling functions with `matlabFunction` → validate speed tracking across lost-traction and heavy-load cases
%[text] Requires: Symbolic Math Toolbox™, Control System Toolbox™
%[text] Copyright 2026 The MathWorks, Inc.
%%
%[text] ## 1. Symbolic System Modeling
%[text] Four states model the motor-shaft-load drivetrain: motor speed $\\omega\_m$, armature current $i$, shaft twist angle $\\Delta\\theta$, and load speed $\\omega\_L$. Input: armature voltage $V$. Output: load speed $\\omega\_L$. The flexible shaft coupling (stiffness $K\_s$, damping $C\_s$) between motor and load creates a torsional resonance, which is the key dynamic that shifts with $J\_L$.
%[text] Governing equations:
%[text] - Motor: $ J\_m \\dot{\\omega}\_m = K\_m i - b\_m \\omega\_m - K\_s \\Delta\\theta - C\_s(\\omega\_m - \\omega\_L) $
%[text] - Electrical: $ L \\dot{i} = V - Ri - K\_m \\omega\_m $
%[text] - Shaft: $ \\dot{\\Delta\\theta} = \\omega\_m - \\omega\_L $
%[text] - Load: $ J\_L \\dot{\\omega}\_L = K\_s \\Delta\\theta + C\_s(\\omega\_m - \\omega\_L) - b\_L \\omega\_L $ \
%[text] Physical parameters: $J\_m$ - motor inertia \[kg·m²\], $J\_L$ - load inertia, $b\_m$/$b\_L$ - friction \[N·m·s\], $K\_m$ - motor constant \[V/(rad/s)\], $R$ - resistance \[Ω\], $L$ - inductance \[H\], $K\_s$ - shaft stiffness \[N·m/rad\], $C\_s$ - shaft damping \[N·m·s\].
syms J_L J_m b_m b_L Km R L K_s C_s positive
A = [(-b_m - C_s)/J_m,  Km/J_m,  -K_s/J_m,   C_s/J_m;
     -Km/L,             -R/L,     0,           0;
      1,                 0,        0,          -1;
      C_s/J_L,           0,        K_s/J_L,   (-b_L - C_s)/J_L];
B = [0; 1/L; 0; 0];
C = [0 0 0 1];
D = 0;
disp('State-space model (symbolic):')
%[text] A =
A
%[text] B =
B
%%
%[text] ## 2. Open-Loop Dynamics: How Load Inertia Affects the Plant
%[text] Substitute known motor and shaft constants but keep $J\_L$ symbolic. Sweeping $J\_L$ reveals two key effects: the plant poles migrate in the complex plane, and the torsional resonance peak shifts in the frequency response. This is the core problem that motivates adaptive control.
J_m_val = 0.05; b_m_val = 0.01; b_L_val = 0.005;
Km_val = 0.1; R_val = 0.5; L_val = 0.005;
K_s_val = 50; C_s_val = 0.5;
motor_params = [J_m b_m b_L Km R L K_s C_s];
motor_values = [J_m_val b_m_val b_L_val Km_val R_val L_val K_s_val C_s_val];
A_motor = subs(A, motor_params, motor_values);
B_Val = double(subs(B, motor_params, motor_values));
C_Val = double(C);
D_Val = double(D);
% Sweep J_L and compute eigenvalues numerically
J_L_range = linspace(0.01, 0.5, 200);
n_pts = length(J_L_range);
all_re = zeros(4*n_pts, 1);
all_im = zeros(4*n_pts, 1);
all_JL = zeros(4*n_pts, 1);
for idx = 1:n_pts
    A_n = double(subs(A_motor, J_L, J_L_range(idx)));
    ev = eig(A_n);
    rows = (4*(idx-1)+1):(4*idx);
    all_re(rows) = real(ev);
    all_im(rows) = imag(ev);
    all_JL(rows) = J_L_range(idx);
end
tiledlayout(2, 1)
nexttile
scatter(all_re, all_im, 8, all_JL, 'filled')
xlabel('Real'); ylabel('Imaginary')
title('Open-Loop Poles vs. Load Inertia J_L')
colormap(parula); clim([0.01 0.5])
cb = colorbar; cb.Label.String = 'J_L [kg.m^2]';
grid on
nexttile
hold on
J_L_bode = [0.01, 0.05, 0.2, 0.5];
labels_bode = ["Lost traction", "Sedan", "SUV", "Truck"];
colors_bode = lines(length(J_L_bode));
w = logspace(-1, 3, 500);
for idx = 1:length(J_L_bode)
    A_n = double(subs(A_motor, J_L, J_L_bode(idx)));
    sys_ol = ss(A_n, B_Val, C_Val, D_Val);
    [mag, ~, ~] = bode(sys_ol, w);
    semilogx(w, 20*log10(squeeze(mag)), 'Color', colors_bode(idx,:), ...
        'LineWidth', 1.5, 'DisplayName', sprintf('J_L=%.2f (%s)', J_L_bode(idx), labels_bode(idx)));
end
xlabel('Frequency [rad/s]'); ylabel('Magnitude [dB]')
title('Bode: V \rightarrow \omega_L')
legend('Location', 'eastoutside')
grid on
%%
%[text] ## 3. State Feedback Gains as Functions of $J\_L$
%[text] Design a state feedback controller: $u = -Kx + \\bar{N}r$. The desired closed-loop poles define the performance spec. Because the system matrix $A$ contains symbolic $J\_L$, the four gains $K = \[k\_1, k\_2, k\_3, k\_4\]$ come out as functions of $J\_L$.
%[text] **Deployment note:** This example assumes full-state feedback. In production hardware, shaft twist angle $\\Delta\\theta$ is usually estimated rather than measured, so an observer such as a Luenberger observer or EKF would provide $\\hat{x}$ from motor current, motor speed, and wheel/load speed sensor data.
n = size(A, 1);
Co = [B, A*B, A^2*B, A^3*B];
det_Co = simplify(det(Co));
fprintf(['Controllability matrix determinant: %s\n' ...
    '  (nonzero for all physically realistic vehicle parameter ranges where J_L*K_s ~= C_s*b_L)\n\n'], ...
    char(det_Co))
% Desired closed-loop poles:
%   -100       fast electrical mode (near natural L/R pole)
%   -15        moderate real pole
%   -8 +/- 8i  dominant complex pair (zeta=0.71, settling ~0.5s)
p_des = [-100, -15, -8+8i, -8-8i];
fprintf(['Desired poles: -100, -15, -8+8i, -8-8i\n' ...
    '  (dominant pair: zeta=0.71, ~4%% overshoot, ~0.5s settling)\n\n'])
% Symbolic pole placement: solve for K such that eig(A - B*K) = p_des
syms lambda
k = sym('k', [1, n]);
char_eqn = det(A - B*k - lambda*eye(n));
eqns = subs(char_eqn, lambda, p_des);
sol = solve(eqns, k);
K_sym = [sol.k1, sol.k2, sol.k3, sol.k4];
%[text] State feedback gains K(J\_L):
% Selective substitution: fix motor/shaft constants, keep J_L free
K_of_JL = simplify(subs(K_sym, motor_params, motor_values))
%%
%[text] ## Precompensator $\\bar{N}(J\_L)$ for Zero Steady-State Error
%[text] Compute reference scaling so load speed tracks the setpoint. Since $K$ and the system matrices depend on $J\_L$, so does $\\bar{N}$.
N_ss = [A, B; C, D] \ [zeros(n, 1); 1];
Nx = N_ss(1:n);
Nu = N_ss(end);
Nbar_sym = Nu + K_sym * Nx;
%[text] Reference scaling Nbar(J\_L):
Nbar_of_JL = simplify(subs(Nbar_sym, motor_params, motor_values))
%[text] Complete control law: $ u = -K(J\_L) \\cdot x + \\bar{N}(J\_L) \\cdot r $
%%
%[text] ## 4. Verification: Desired Poles Are Achieved for Any $J\_L$
%[text] Form the closed-loop system and confirm the eigenvalues match the desired poles regardless of load inertia. Step responses show identical settling behavior across the full $J\_L$ range.
A_cl = A - B*K_sym;
A_cl_of_JL = simplify(subs(A_cl, motor_params, motor_values));
J_L_test = [0.01, 0.05, 0.2, 0.5];
labels = ["Lost traction", "Sedan", "SUV", "Truck"];
fprintf('Closed-loop pole verification:\n')
for idx = 1:length(J_L_test)
    poles_cl = eig(double(subs(A_cl_of_JL, J_L, J_L_test(idx))));
    poles_cl = sort(poles_cl, 'ComparisonMethod', 'real');
    fprintf('  J_L = %.2f (%s):', J_L_test(idx), labels(idx));
    for p = 1:length(poles_cl)
        fprintf('  %.1f%+.1fi', real(poles_cl(p)), imag(poles_cl(p)));
    end
    fprintf('\n');
end
% Step responses across the inertia range
clf
t = 0:0.001:1.5;
colors = lines(length(J_L_test));
hold on
for idx = 1:length(J_L_test)
    J_val = J_L_test(idx);
    A_n = double(subs(A_motor, J_L, J_val));
    K_n = double(subs(K_of_JL, J_L, J_val));
    Nbar_n = double(subs(Nbar_of_JL, J_L, J_val));
    sys_cl = ss(A_n - B_Val*K_n, B_Val*Nbar_n, C_Val, D_Val);
    [y, ~] = step(sys_cl, t);
    plot(t, y, 'Color', colors(idx,:), 'LineWidth', 2, ...
        'DisplayName', sprintf('J_L=%.2f (%s)', J_val, labels(idx)))
end
legend('Location', 'eastoutside')
title('Adaptive Gains Maintain Performance Across Inertia Range')
xlabel('Time [s]'); ylabel('Load speed \omega_L [rad/s]')
grid on
%%
%[text] ## Fixed vs. Adaptive Gains
%[text] What happens when gains designed for one $J\_L$ are used at a different $J\_L$? Scenario: controller tuned for low inertia / lost traction ($J\_L = 0.02$), then applied when the load inertia increases to a heavy-vehicle condition ($J\_L = 0.20$). The low-inertia fixed gains are too aggressive for the heavier plant and move the closed-loop poles into the right-half plane.
J_L_design = 0.02;
J_L_actual = 0.2;
% Fixed gains (designed for J_L_design, applied at J_L_actual)
K_fixed = double(subs(K_of_JL, J_L, J_L_design));
Nbar_fixed = double(subs(Nbar_of_JL, J_L, J_L_design));
A_actual = double(subs(A_motor, J_L, J_L_actual));
sys_fixed = ss(A_actual - B_Val*K_fixed, B_Val*Nbar_fixed, C_Val, D_Val);
%[text] Fixed-gain closed-loop poles for the mismatched plant:
poles_fixed_mismatch = eig(A_actual - B_Val*K_fixed)
% Adaptive gains (correct for J_L_actual)
K_adapt = double(subs(K_of_JL, J_L, J_L_actual));
Nbar_adapt = double(subs(Nbar_of_JL, J_L, J_L_actual));
sys_adapt = ss(A_actual - B_Val*K_adapt, B_Val*Nbar_adapt, C_Val, D_Val);
t = 0:0.0005:0.6;
[y_fixed, ~] = step(sys_fixed, t);
[y_adapt, ~] = step(sys_adapt, t);
clf
plot(t, y_fixed, 'r--', 'LineWidth', 2); hold on
plot(t, y_adapt, 'b-', 'LineWidth', 2);
yline(1, ':k');
legend('Fixed gains (designed for J_L = 0.02)', ...
       'Adaptive gains K(J_L = 0.20)', 'Location', 'eastoutside')
title('Load Increase: Fixed vs. Adaptive Control')
xlabel('Time [s]'); ylabel('Load speed \omega_L [rad/s]')
ylim([-0.2 2.5])
grid on
%[text] The plot limits keep the adaptive response visible while the fixed-gain response leaves the useful speed range. In practice, the armature voltage $V$ is limited by the power electronics (e.g., 48 V), so a production controller would also include voltage limiting and anti-windup.
%%
%[text] ## 5. Code Generation: Deployable Controller Functions
%[text] Generate MATLAB® and C code from the symbolic expressions for use in simulation. These functions take $J\_L$ as input and return the correct gains.
matlabFunction(K_of_JL, 'File', 'controllerGains', 'Vars', {J_L}, ...
    'Outputs', {'K'});
matlabFunction(Nbar_of_JL, 'File', 'referenceScaling', 'Vars', {J_L}, ...
    'Outputs', {'Nbar'});
fprintf('\n--- Generated controllerGains.m ---\n')
type controllerGains.m
fprintf('\n--- Generated referenceScaling.m ---\n')
type referenceScaling.m
% C code for external use
fprintf('\n--- C code for K(J_L) ---\n')
ccode(K_of_JL)
%%
%[text] ## 6. Simulink® Integration
%[text] The generated functions can be called directly from MATLAB Function blocks in Simulink. The model architecture:
%[text] ```
%[text]                    J_L_est (from estimator, lookup, or traction module)
%[text]                      |            |               |
%[text]                      v            v               v
%[text] r -----> [Nbar(JL)] -->(+)----> u ---> [Plant(JL)] ----> y
%[text]                        ^(-)               |
%[text]                        |                  v
%[text]                        +---- [K(JL)] <--- x (state feedback)
%[text] ```
%[text] ```matlabCodeExample
%[text] - controllerGains(J_L) computes the 1x4 state feedback gain vector K
%[text] - referenceScaling(J_L) computes the precompensator Nbar
%[text] - J_L can come from a lookup table, an online estimator,
%[text]   or the traction control module
%[text] ```
%[text] Run buildSimulinkModel.m to create a working Simulink model that demonstrates this architecture with a traction-loss scenario ($J\_L$ switches from 0.2 to 0.02 at $t = 5$ seconds).
%[text] For direct Simulink block generation: matlabFunctionBlock('model/block', K\_of\_JL, 'Vars', {J\_L})

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
