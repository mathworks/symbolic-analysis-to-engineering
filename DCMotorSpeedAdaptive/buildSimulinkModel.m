%% buildSimulinkModel
%     Copyright 2026 The MathWorks, Inc.
%
% Creates a Simulink model demonstrating the adaptive DC motor speed
% controller with a traction-loss scenario.
%
% Prerequisites: Run DCMotorSpeedAdaptive.m first to generate
%   controllerGains.m and referenceScaling.m
%
% The model simulates a 4-state drivetrain (motor speed, current,
% shaft twist, load speed). J_L = 0.2 (full traction) for t <= 5s,
% then J_L = 0.02 (traction loss) for t > 5s. The controller gains
% adapt automatically via the generated functions.

%% Check prerequisites
if ~exist('controllerGains.m', 'file') || ~exist('referenceScaling.m', 'file')
    error(['controllerGains.m and referenceScaling.m not found.\n' ...
           'Run DCMotorSpeedAdaptive.m first to generate them.'], []);
end

%% Create model
modelName = 'DCMotorSpeedAdaptiveModel';
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
if exist([modelName '.slx'], 'file')
    delete([modelName '.slx']);
end
new_system(modelName);
open_system(modelName);

set_param(modelName, 'Solver', 'ode45', 'StopTime', '10', ...
    'SolverType', 'Variable-step', 'MaxStep', '0.001');

%% Add blocks -- J_L signal chain (selects load inertia based on time)
add_block('simulink/Sources/Clock', [modelName '/Clock'], ...
    'Position', [30 50 60 70]);

add_block('simulink/Logic and Bit Operations/Compare To Constant', ...
    [modelName '/t_leq_5'], ...
    'Position', [100 47 155 73], ...
    'const', '5', 'relop', '<=');

add_block('simulink/Sources/Constant', [modelName '/JL_traction'], ...
    'Position', [100 15 170 35], 'Value', '0.2');

add_block('simulink/Sources/Constant', [modelName '/JL_no_traction'], ...
    'Position', [100 90 170 110], 'Value', '0.02');

add_block('simulink/Signal Routing/Switch', [modelName '/JL_Switch'], ...
    'Position', [210 18 250 107], 'Criteria', 'u2 ~= 0');

%% Add blocks -- main signal path
add_block('simulink/Sources/Step', [modelName '/Reference'], ...
    'Position', [30 190 60 210], ...
    'Time', '0', 'After', '1', 'Before', '0');

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/Controller'], ...
    'Position', [230 155 370 245]);

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [modelName '/Plant'], ...
    'Position', [440 155 580 245]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator'], ...
    'Position', [640 185 680 215], ...
    'InitialCondition', '[0; 0; 0; 0]');

%% Add blocks -- output
add_block('simulink/Signal Routing/Demux', [modelName '/Demux'], ...
    'Position', [730 167 735 233], 'Outputs', '4');

add_block('simulink/Sinks/Scope', [modelName '/Motor Speed'], ...
    'Position', [790 155 820 175]);

add_block('simulink/Sinks/Scope', [modelName '/Load Speed'], ...
    'Position', [790 220 820 240]);

%% Set MATLAB Function block code via Stateflow API
rt = sfroot;

% Controller: u = -K(J_L)*x + Nbar(J_L)*r
controllerChart = rt.find('-isa', 'Stateflow.EMChart', ...
    'Path', [modelName '/Controller']);
controllerChart.Script = sprintf([ ...
    'function u = controller(x, r, JL_val) %%#codegen\n' ...
    '%%%% Adaptive state feedback controller.\n' ...
    '%%%% Calls generated functions controllerGains(JL) and referenceScaling(JL).\n' ...
    'K = controllerGains(JL_val);\n' ...
    'Nbar = referenceScaling(JL_val);\n' ...
    'u = -K*x + Nbar*r;\n' ...
    'end\n']);

% Plant: xdot = A(J_L)*x + B*u
plantChart = rt.find('-isa', 'Stateflow.EMChart', ...
    'Path', [modelName '/Plant']);
plantChart.Script = sprintf([ ...
    'function xdot = plantDynamics(x, u, JL_val) %%#codegen\n' ...
    '%%%% 4-state drivetrain: x = [omega_m; i; delta_theta; omega_L]\n' ...
    'J_m = 0.05; b_m = 0.01; b_L = 0.005;\n' ...
    'Km = 0.1; R = 0.5; L = 0.005;\n' ...
    'K_s = 50; C_s = 0.5;\n' ...
    'A = [(-b_m - C_s)/J_m,  Km/J_m,  -K_s/J_m,   C_s/J_m;\n' ...
    '     -Km/L,             -R/L,     0,           0;\n' ...
    '      1,                 0,        0,          -1;\n' ...
    '      C_s/JL_val,        0,        K_s/JL_val, (-b_L - C_s)/JL_val];\n' ...
    'B = [0; 1/L; 0; 0];\n' ...
    'xdot = A*x + B*u;\n' ...
    'end\n']);

%% Connect blocks
% J_L signal chain
add_line(modelName, 'Clock/1',          't_leq_5/1');
add_line(modelName, 'JL_traction/1',    'JL_Switch/1');
add_line(modelName, 't_leq_5/1',        'JL_Switch/2');
add_line(modelName, 'JL_no_traction/1', 'JL_Switch/3');

% J_L to Controller (port 3) and Plant (port 3)
add_line(modelName, 'JL_Switch/1', 'Controller/3', 'autorouting', 'smart');
add_line(modelName, 'JL_Switch/1', 'Plant/3',      'autorouting', 'smart');

% Reference to Controller (port 2)
add_line(modelName, 'Reference/1', 'Controller/2', 'autorouting', 'smart');

% Controller output to Plant (port 2)
add_line(modelName, 'Controller/1', 'Plant/2', 'autorouting', 'smart');

% Plant to Integrator
add_line(modelName, 'Plant/1', 'Integrator/1', 'autorouting', 'smart');

% Integrator output (state x) to Demux
add_line(modelName, 'Integrator/1', 'Demux/1', 'autorouting', 'smart');

% Demux outputs to Scopes (port 1 = omega_m, port 4 = omega_L)
add_line(modelName, 'Demux/1', 'Motor Speed/1', 'autorouting', 'smart');
add_line(modelName, 'Demux/4', 'Load Speed/1',  'autorouting', 'smart');

% State feedback: Integrator output back to Controller (port 1) and Plant (port 1)
add_line(modelName, 'Integrator/1', 'Controller/1', 'autorouting', 'smart');
add_line(modelName, 'Integrator/1', 'Plant/1',      'autorouting', 'smart');

%% Annotate
add_block('built-in/Note', [modelName '/Note'], ...
    'Position', [30 130 400 145], ...
    'Text', 'Adaptive DC Motor Speed Control — J_L switches from 0.2 to 0.02 at t=5');

%% Save
save_system(modelName);
fprintf('Created and saved: %s.slx\n', modelName);
fprintf('To simulate: sim(''%s'')\n', modelName);
