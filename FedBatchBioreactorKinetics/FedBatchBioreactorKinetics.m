%[text] # Fed-Batch Bioreactor Kinetics with Units and Engineering Handoff
%[text] This example derives a temperature-dependent fed-batch bioreactor model from kinetic assumptions, checks units before numeric handoff, generates reusable MATLAB® functions, and reuses those functions in compact simulation, local linearization, and a rate-law handoff ready for SimBiology®.
%[text] **Workflow:** enzyme mechanism -\> symbolic rate law -\> unit audit -\> fed-batch balances -\> batch limit -\> Jacobians -\> generated functions -\> simulation, state-space analysis, and SimBiology rate reuse.
%[text] Requires: MATLAB R2025a or later, Symbolic Math Toolbox™. Optional: SimBiology, Control System Toolbox™.
%[text] Copyright 2026 The MathWorks, Inc.
%%
%[text] ## 1. Derive the kinetic rate law from enzyme-complex assumptions
%[text] Start from the enzyme-mediated conversion $E + S \\rightleftharpoons C \\rightarrow E + P$, where $C$ is the enzyme-substrate complex. The quasi-steady-state approximation sets $dC/dt = 0$ and enzyme conservation sets $E\_T = E + C$.
syms kForward kReverse kcat enzymeFree substrate enzymeComplex enzymeTotal positive
qssaEquation = kForward*enzymeFree*substrate - kReverse*enzymeComplex - kcat*enzymeComplex == 0;
enzymeConservation = enzymeTotal == enzymeFree + enzymeComplex;
kineticSolution = solve([qssaEquation, enzymeConservation], [enzymeFree, enzymeComplex]);
complexQSSA = simplify(kineticSolution.enzymeComplex);
rateDerived = simplify(kcat*complexQSSA);
syms Vmax Km positive
rateCanonical = Vmax*substrate/(Km + substrate);
rateDefinitionCheck = simplify(subs(rateCanonical, ...
    [Vmax, Km], ...
    [kcat*enzymeTotal, (kReverse + kcat)/kForward]) - rateDerived)
%[text] The check returns zero, so the symbolic derivation recovers the Michaelis-Menten form with $V\_{max}=k\_{cat}E\_T$ and $K\_m=(k\_{-1}+k\_{cat})/k\_1$.
%[text] The fed-batch model below reuses this saturation structure as a Monod-style specific growth law. It carries the first-principles saturation result into a microbial growth model without implying that whole-cell growth is literally a single-enzyme reaction.
%[text:table]
%[text] | Enzyme derivation | Bioreactor growth model | Interpretation |
%[text] | --- | --- | --- |
%[text] | `substrate` | `S` | Limiting substrate concentration |
%[text] | `Vmax` | `muRef*Arrhenius(T)` | Maximum/reference specific growth rate adjusted for temperature |
%[text] | `Km` | `Ks` | Half-saturation constant for substrate-limited growth |
%[text:table]
%%
%[text] ## 2. Add temperature dependence and inspect sensitivity
%[text] With that mapping, use an apparent Arrhenius correction around a reference temperature. This is credible over a narrow calibrated range, not as a universal high-temperature growth model.
syms X S V T muRef Ks Ea R Tref Sf Yxs Ypx real positive
syms P F real
specificGrowthRate = muRef*exp(-(Ea/R)*(1/T - 1/Tref))*S/(Ks + S);
temperatureSensitivity = simplify(diff(specificGrowthRate, T))
isMonotoneInTemperature = isAlways(temperatureSensitivity > 0)
%[text] The derivative is positive under the stated assumptions. An Arrhenius-only model will push a temperature optimization to the upper allowed bound unless biology, data, or operating policy adds a thermal optimum or deactivation term.
%%
%[text] ## 3. Audit units before creating numeric functions
%[text] Symbolic units are regular symbolic expressions that can be converted, simplified, checked, and separated before a downstream solver sees numeric magnitudes. This section uses common lab-scale bioprocess units and includes the Celsius absolute-temperature conversion that is easy to get wrong.
u = symunit;
flowWithUnits = 2*u.ml/u.min;
volumeInitialWithUnits = 2*u.L;
temperatureWithUnits = 33*u.Celsius;
temperatureReferenceWithUnits = 30*u.Celsius;
activationEnergyWithUnits = 55*u.kJ/u.mol;
gasConstantWithUnits = 8.314462618*u.J/(u.mol*u.K);
temperatureAsDifference = unitConvert(temperatureWithUnits, u.K);
temperatureAsAbsolute = unitConvert(temperatureWithUnits, u.K, 'Temperature', 'absolute');
temperatureReferenceAbsolute = unitConvert(temperatureReferenceWithUnits, u.K, 'Temperature', 'absolute');
flowLitersPerHour = unitConvert(flowWithUnits, u.L/u.hr);
dilutionRateWithUnits = unitConvert(flowLitersPerHour/volumeInitialWithUnits, 1/u.hr)
arrheniusExponentWithUnits = unitConvert( ...
    (activationEnergyWithUnits/gasConstantWithUnits)*(1/temperatureAsAbsolute - 1/temperatureReferenceAbsolute), ...
    'SI')
temperatureConversionSummary = [temperatureAsDifference; temperatureAsAbsolute]
%[text] MATLAB treats Celsius values as temperature differences unless `Temperature` is set to `absolute`. The Arrhenius exponent is dimensionless after conversion, which is required before evaluating `exp`.
%%
%[text] ## 4. Verify the fed-batch balance dimensions
%[text] Use unit-bearing placeholders to verify every state derivative has the expected dimension. MATLAB assumes symbolic variables are dimensionless, so the units must be attached explicitly in this audit expression.
%[text] The vector below is a unit-only copy of the fed-batch material balances that are derived symbolically in Section 6. It is written here with placeholder magnitudes such as `muMag`, `dMag`, and `xMag` so the unit check focuses only on dimensions.
%[text:table]
%[text] | Row | Balance | Physical meaning |
%[text] | --- | --- | --- |
%[text] | `dXdt` | `mu*X - D*X` | Biomass grows at specific rate `mu`; feed dilution reduces cell concentration. |
%[text] | `dSdt` | `D*(Sf - S) - mu*X/Yxs` | Feed adds concentrated substrate and dilution removes broth substrate; cells consume substrate to make biomass. |
%[text] | `dPdt` | `Ypx*mu*X - D*P` | Product forms in proportion to growth; feed dilution reduces product concentration. |
%[text] | `dVdt` | `F` | Reactor volume increases at the inlet feed flow rate. |
%[text:table]
syms muMag dMag xMag sMag pMag fMag sfMag yxsMag ypxMag positive
rhsUnitAudit = [(muMag/u.hr)*(xMag*u.g/u.L) - (dMag/u.hr)*(xMag*u.g/u.L);
    (dMag/u.hr)*((sfMag*u.g/u.L) - (sMag*u.g/u.L)) - ((muMag/u.hr)*(xMag*u.g/u.L))/yxsMag;
    ypxMag*(muMag/u.hr)*(xMag*u.g/u.L) - (dMag/u.hr)*(pMag*u.g/u.L);
    fMag*u.L/u.hr];
expectedDerivativeUnits = [u.g/(u.L*u.hr); u.g/(u.L*u.hr); u.g/(u.L*u.hr); u.L/u.hr];
unitAudit = checkUnits(rhsUnitAudit == expectedDerivativeUnits);
unitAuditTable = table(["dXdt"; "dSdt"; "dPdt"; "dVdt"], ...
    unitAudit.Compatible, unitAudit.Consistent, ...
    'VariableNames', {'Derivative', 'Compatible', 'Consistent'})
%[text] The generated functions use numeric magnitudes with time in hours, volume in liters, concentrations in g/L, and temperature in kelvin.
%%
%[text] ## 5. Convert realistic operating parameters to numeric magnitudes
%[text] These values describe a generic glucose-limited lab fed-batch fermentation. They are realistic enough for a process-dynamics example without claiming organism-specific fidelity.
biomassInitialWithUnits = 0.3*u.g/u.L;
substrateInitialWithUnits = 8*u.g/u.L;
productInitialWithUnits = 0*u.g/u.L;
feedSubstrateWithUnits = 250*u.g/u.L;
specificGrowthRefWithUnits = 0.32/u.hr;
halfSaturationWithUnits = 0.25*u.g/u.L;
[FVal, ~] = separateUnits(flowLitersPerHour);
[X0Val, ~] = separateUnits(biomassInitialWithUnits);
[S0Val, ~] = separateUnits(substrateInitialWithUnits);
[P0Val, ~] = separateUnits(productInitialWithUnits);
[V0Val, ~] = separateUnits(volumeInitialWithUnits);
[SfVal, ~] = separateUnits(feedSubstrateWithUnits);
[muRefVal, ~] = separateUnits(specificGrowthRefWithUnits);
[KsVal, ~] = separateUnits(halfSaturationWithUnits);
[TVal, ~] = separateUnits(temperatureAsAbsolute);
[TrefVal, ~] = separateUnits(temperatureReferenceAbsolute);
[EaVal, ~] = separateUnits(unitConvert(activationEnergyWithUnits, u.J/u.mol));
[RVal, ~] = separateUnits(gasConstantWithUnits);
YxsVal = 0.45;
YpxVal = 0.10;
initialStateVal = double([X0Val; S0Val; P0Val; V0Val]);
inputVal = double([FVal; TVal]);
paramVal = double([muRefVal; KsVal; EaVal; RVal; TrefVal; SfVal; YxsVal; YpxVal]);
parameterSummary = table(["muRef"; "Ks"; "Ea"; "R"; "Tref"; "Sf"; "Yxs"; "Ypx"], ...
    paramVal, ...
    ["1/hr"; "g/L"; "J/mol"; "J/(mol*K)"; "K"; "g/L"; "gX/gS"; "gP/gX"], ...
    'VariableNames', {'Parameter', 'Value', 'Units'})
%%
%[text] ## 6. Build the symbolic fed-batch material balances
%[text] The state vector is $x=\[X,S,P,V\]^T$. The input vector is $u=\[F,T\]^T$. Feed flow $F$ is retained as the physical manipulated variable, with dilution rate $D=F/V$ defined inside the model.
stateVars = [X; S; P; V];
inputVars = [F; T];
paramVars = [muRef; Ks; Ea; R; Tref; Sf; Yxs; Ypx];
dilutionRate = F/V;
fedBatchRHS = [specificGrowthRate*X - dilutionRate*X;
    dilutionRate*(Sf - S) - specificGrowthRate*X/Yxs;
    Ypx*specificGrowthRate*X - dilutionRate*P;
    F];
fedBatchRHS = simplify(fedBatchRHS)
%[text] Keeping this expression symbolic makes the state, input, and parameter dependencies inspectable before they are hidden inside a numerical solver.
%%
%[text] ## 7. Recover the batch model as a special case
%[text] Setting the feed flow to zero removes dilution and volume growth. This boundary case is a useful check because a fed-batch model should contain the batch model as a limiting case.
batchRHS = simplify(subs(fedBatchRHS, F, 0))
batchCheck = simplify(batchRHS - [specificGrowthRate*X; -specificGrowthRate*X/Yxs; Ypx*specificGrowthRate*X; 0])
%[text] The check returns zeros, confirming that no extra feed terms remain in the batch limit.
%%
%[text] ## 8. Use symbolic algebra to separate concentration dilution from product mass
%[text] Feed flow immediately dilutes product concentration, so $\\partial \\dot{P}/\\partial F=-P/V$. The total product mass $M\_P=PV$ answers a different question; differentiating $PV$ with the chain rule shows the dilution terms cancel.
productMass = P*V;
productMassRate = simplify(jacobian(productMass, stateVars)*fedBatchRHS)
productConcentrationFeedSensitivity = simplify(diff(fedBatchRHS(3), F))
productMassFeedSensitivity = simplify(diff(productMassRate, F))
%[text] This is the natural iteration point. If the downstream objective is product concentration, feed appears as a direct dilution penalty. If the objective is total product mass, feed affects the trajectory indirectly through substrate and volume, not through an instantaneous dilution term.
%%
%[text] ## 9. Compute Jacobians for local linearization and sensitivity analysis
%[text] The same symbolic RHS gives the state and input Jacobians needed for local linear models, stiffness checks, sensitivity ODEs, and controller interpretation.
stateJacobian = simplify(jacobian(fedBatchRHS, stateVars));
inputJacobian = simplify(jacobian(fedBatchRHS, inputVars));
size(stateJacobian)
size(inputJacobian)
%[text] The matrices stay symbolic until a specific operating point is selected.
%%
%[text] ## 10. Generate reusable MATLAB functions
%[text] Use explicit argument groups so every generated function has the same calling convention. The generated functions are numeric and unit-free because the unit conversion happened upstream.
productivityRate = simplify(Ypx*specificGrowthRate*X);
productivityGradient = simplify(jacobian(productivityRate, [S, T]));
matlabFunction(specificGrowthRate, temperatureSensitivity, ...
    'File', 'bioreactorRates', ...
    'Vars', {S, T, muRef, Ks, Ea, R, Tref}, ...
    'Outputs', {'mu', 'dmu_dT'}, ...
    'Optimize', true);
matlabFunction(fedBatchRHS, ...
    'File', 'fedBatchBioreactorRHS', ...
    'Vars', {stateVars, inputVars, paramVars}, ...
    'Outputs', {'dstate'}, ...
    'Optimize', true);
matlabFunction(stateJacobian, inputJacobian, ...
    'File', 'bioreactorJacobian', ...
    'Vars', {stateVars, inputVars, paramVars}, ...
    'Outputs', {'A', 'B'}, ...
    'Optimize', true);
matlabFunction(productivityRate, ...
    'File', 'bioreactorProductivity', ...
    'Vars', {stateVars, inputVars, paramVars}, ...
    'Outputs', {'productivity'}, ...
    'Optimize', true);
matlabFunction(productivityGradient, ...
    'File', 'bioreactorProductivityGradient', ...
    'Vars', {stateVars, inputVars, paramVars}, ...
    'Outputs', {'gradientST'}, ...
    'Optimize', true);
generatedFiles = ["bioreactorRates.m"; "fedBatchBioreactorRHS.m"; ...
    "bioreactorJacobian.m"; "bioreactorProductivity.m"; "bioreactorProductivityGradient.m"]
%%
%[text] ## 11. Simulate the fed-batch process using the generated RHS and Jacobian
%[text] The solver receives only numeric magnitudes. The generated Jacobian is supplied to `ode15s`, which is the same handoff pattern used in larger process simulation workflows.
timeSpanVal = [0 12];
odeOptions = odeset('Jacobian', @(timeVal, stateVal) bioreactorJacobian(stateVal, inputVal, paramVal), ...
    'NonNegative', 1:4);
[timeSol, stateSol] = ode15s(@(timeVal, stateVal) fedBatchBioreactorRHS(stateVal, inputVal, paramVal), ...
    timeSpanVal, initialStateVal, odeOptions);
productMassSol = stateSol(:, 3).*stateSol(:, 4);
simulationSummary = table(["X"; "S"; "P"; "V"; "P*V"], ...
    [stateSol(1, :)'; productMassSol(1)], ...
    [stateSol(end, :)'; productMassSol(end)], ...
    ["g/L"; "g/L"; "g/L"; "L"; "g"], ...
    'VariableNames', {'Quantity', 'Initial', 'Final', 'Units'})
%%
%[text] ## 12. Visualize concentration and product-mass trajectories
%[text] Concentrations and total product mass tell different engineering stories, so plot both. The concentration traces are what a sensor or soft sensor sees; total product mass is closer to the production objective.
tiledlayout(2, 1)
nexttile
plot(timeSol, stateSol(:, 1), 'LineWidth', 2)
hold on
plot(timeSol, stateSol(:, 2), 'LineWidth', 2)
plot(timeSol, stateSol(:, 3), 'LineWidth', 2)
hold off
xlabel('Time [hr]')
ylabel('Concentration [g/L]')
title('Fed-Batch Concentration Dynamics')
legend('Biomass X', 'Substrate S', 'Product P', 'Location', 'northwest')
grid on
nexttile
plot(timeSol, stateSol(:, 4), 'LineWidth', 2)
hold on
plot(timeSol, productMassSol, 'LineWidth', 2)
hold off
xlabel('Time [hr]')
ylabel('Volume [L] and Product Mass [g]')
title('Volume Expansion and Product Accumulation')
legend('Volume V', 'Product mass P V', 'Location', 'northwest')
grid on
%%
%[text] ## 13. Evaluate a local perturbation model along the trajectory
%[text] A downstream controller or sensitivity analysis normally starts from a current operating condition. In fed-batch operation, the 12-hour simulated state is not a steady state because the volume and concentrations are still changing. The symbolic Jacobians still provide the local perturbation matrices $A$ and $B$ for small changes around that condition.
stateOperatingPointVal = stateSol(end, :)';
operatingDerivativeVal = fedBatchBioreactorRHS(stateOperatingPointVal, inputVal, paramVal);
[AOperatingVal, BOperatingVal] = bioreactorJacobian(stateOperatingPointVal, inputVal, paramVal);
operatingDerivativeSummary = table(["dXdt"; "dSdt"; "dPdt"; "dVdt"], ...
    operatingDerivativeVal, ...
    ["g/(L hr)"; "g/(L hr)"; "g/(L hr)"; "L/hr"], ...
    'VariableNames', {'Derivative', 'Value', 'Units'})
eigenvaluesVal = eig(AOperatingVal);
localDynamicsSummary = table((1:numel(eigenvaluesVal))', eigenvaluesVal, ...
    'VariableNames', {'Mode', 'Eigenvalue_per_hr'})
inputSensitivitySummary = table(["feed flow F"; "temperature T"], ...
    BOperatingVal(3, :)', ...
    ["(g/L/hr)/(L/hr)"; "(g/L/hr)/K"], ...
    'VariableNames', {'Input', 'dPdtSensitivity', 'Units'})
%[text] The nonzero derivative table marks this as a trajectory linearization, not an equilibrium model. The feed-flow sensitivity of $\\dot{P}$ is negative at this operating condition because concentration is diluted immediately. The total product-mass rate had zero direct feed sensitivity in Section 8, which is why selecting the right objective matters before optimization.
%%
%[text] ## 14. Inspect local productivity sensitivities
%[text] Use the generated productivity function and symbolic gradient to see which variables the product formation rate responds to at the simulated operating condition. The positive temperature derivative is consistent with the monotonicity result in Section 2, so this stops at sensitivity rather than pretending the Arrhenius-only model has an interior optimum.
productivityOperatingVal = bioreactorProductivity(stateOperatingPointVal, inputVal, paramVal);
productivityGradientOperatingVal = bioreactorProductivityGradient(stateOperatingPointVal, inputVal, paramVal);
productivitySensitivitySummary = table(productivityOperatingVal, ...
    productivityGradientOperatingVal(1), productivityGradientOperatingVal(2), ...
    'VariableNames', {'Productivity_g_per_L_hr', 'dProductivity_dS', 'dProductivity_dT'})
%%
%[text] ## 15. Hand off the generated Jacobian for local analysis
%[text] The generated Jacobian now becomes an engineering object. Because the linearization point is not a steady state, an absolute local model would include the affine offset $f(x\_0,u\_0)$ shown in Section 13. For input-output perturbation analysis around the nominal trajectory, the handoff uses $\\Delta \\dot{x}=A\\Delta x+B\\Delta u$ and $\\Delta y=C\\Delta x+D\\Delta u$.
%[text] View the same state dynamics through product concentration $P$ and total product mass $M\_P=PV$. This keeps the control-analysis handoff focused on the symbolic result from Section 8 instead of turning the example into a controller-design walkthrough.
productConcentrationOutputVal = [0 0 1 0];
productMassOutputVal = [0 0 stateOperatingPointVal(4) stateOperatingPointVal(3)];
outputMatrixCVal = [productConcentrationOutputVal; productMassOutputVal];
directMatrixDVal = zeros(2, 2);
outputRateSensitivityVal = outputMatrixCVal*BOperatingVal;
outputRateSensitivitySummary = table(["Product concentration P"; "Total product mass P*V"], ...
    outputRateSensitivityVal(:, 1), outputRateSensitivityVal(:, 2), ...
    ["(g/L/hr)/(L/hr)"; "(g/hr)/(L/hr)"], ...
    ["(g/L/hr)/K"; "(g/hr)/K"], ...
    'VariableNames', {'Output', 'FeedRateSensitivity', 'TemperatureRateSensitivity', 'FeedUnits', 'TemperatureUnits'})
stateDisplayNames = {'Biomass_X'; 'Substrate_S'; 'Product_P'; 'Volume_V'};
inputDisplayNames = {'FeedFlow_F'; 'Temperature_T'};
outputDisplayNames = {'ProductConcentration_P'; 'TotalProductMass_PV'};
stateSpaceHandoffSummary = table(["A"; "B"; "C"; "D"; "f(x0,u0)"], ...
    ["4 x 4"; "4 x 2"; "2 x 4"; "2 x 2"; "4 x 1"], ...
    ["State perturbation dynamics"; "Input perturbation sensitivities"; ...
    "Output definitions"; "Direct input-to-output terms"; "Affine offset for an absolute local model"], ...
    'VariableNames', {'Artifact', 'Size', 'Meaning'})
hasControlSystemToolbox = (exist('ss', 'file') == 2) && license('test', 'Control_Toolbox');
if hasControlSystemToolbox
    productOutputModel = ss(AOperatingVal, BOperatingVal, outputMatrixCVal, directMatrixDVal);
    productOutputModel.InputName = {'Feed flow F'; 'Temperature T'};
    productOutputModel.OutputName = {'Product concentration P'; 'Total product mass P*V'};
    productOutputModel.StateName = {'Biomass X'; 'Substrate S'; 'Product P'; 'Volume V'};
    stateSpaceObjectSummary = table("ss", numel(productOutputModel.InputName), ...
        numel(productOutputModel.OutputName), ...
        'VariableNames', {'ObjectType', 'Inputs', 'Outputs'})
else
    productOutputModel = struct('A', AOperatingVal, 'B', BOperatingVal, ...
        'C', outputMatrixCVal, 'D', directMatrixDVal, 'Offset', operatingDerivativeVal, ...
        'StateNames', {stateDisplayNames}, 'InputNames', {inputDisplayNames}, ...
        'OutputNames', {outputDisplayNames});
    stateSpaceObjectSummary = table("struct", numel(inputDisplayNames), ...
        numel(outputDisplayNames), ...
        'VariableNames', {'ObjectType', 'Inputs', 'Outputs'})
end
%[text] The feed-flow column shows immediate dilution of concentration, while total product mass has zero direct feed-flow rate sensitivity at the same state.
%%
%[text] ## 16. Validate the symbolic rate law for SimBiology reuse
%[text] A SimBiology model can reuse the same rate expression when the model quantities use concentration in g/L, time in hours, temperature in kelvin, and activation energy in J/mol. Before making any SimBiology API calls, check the exported expressions as a handoff contract in which every symbol has a downstream role, unit, and value or initial condition.
simbiologyUnitMap = table(["X"; "S"; "P"; "Ks"; "muRef"; "Ea"; "R"; "T"; "Tref"; "Yxs"; "Ypx"], ...
    ["species"; "species"; "species"; "parameter"; "parameter"; "parameter"; "parameter"; "parameter"; "parameter"; "parameter"; "parameter"], ...
    ["gram/liter"; "gram/liter"; "gram/liter"; "gram/liter"; "1/hour"; "joule/mole"; "joule/mole/kelvin"; "kelvin"; "kelvin"; "dimensionless"; "dimensionless"], ...
    'VariableNames', {'SimBiologyName', 'Role', 'Unit'})
simbiologySpeciesHandoff = table(["X"; "S"; "P"], ...
    initialStateVal(1:3), ...
    ["gram/liter"; "gram/liter"; "gram/liter"], ...
    'VariableNames', {'Name', 'InitialValue', 'Unit'})
simbiologyParameterHandoff = table(["muRef"; "Ks"; "Ea"; "R"; "T"; "Tref"; "Yxs"; "Ypx"], ...
    [paramVal(1); paramVal(2); paramVal(3); paramVal(4); inputVal(2); paramVal(5); paramVal(7); paramVal(8)], ...
    ["1/hour"; "gram/liter"; "joule/mole"; "joule/mole/kelvin"; "kelvin"; "kelvin"; "dimensionless"; "dimensionless"], ...
    'VariableNames', {'Name', 'Value', 'Unit'})
muForSimBiology = simplify(specificGrowthRate);
growthRateForSimBiology = simplify(muForSimBiology*X);
substrateUptakeRateForSimBiology = simplify(muForSimBiology*X/Yxs);
productFormationRateForSimBiology = simplify(Ypx*muForSimBiology*X);
simbiologyExpressions = [muForSimBiology; growthRateForSimBiology; ...
    substrateUptakeRateForSimBiology; productFormationRateForSimBiology];
handoffSymbolNames = string(arrayfun(@char, symvar(simbiologyExpressions), 'UniformOutput', false))';
hasUnitMapping = ismember(handoffSymbolNames, simbiologyUnitMap.SimBiologyName);
hasValueOrInitialCondition = ismember(handoffSymbolNames, ...
    [simbiologySpeciesHandoff.Name; simbiologyParameterHandoff.Name]);
simbiologyHandoffContract = table(handoffSymbolNames, hasUnitMapping, hasValueOrInitialCondition, ...
    'VariableNames', {'Symbol', 'HasUnitMapping', 'HasValueOrInitialCondition'})
assert(all(simbiologyHandoffContract.HasUnitMapping) && ...
    all(simbiologyHandoffContract.HasValueOrInitialCondition), ...
    "Every exported SimBiology rate-law symbol must have a unit mapping and a value or initial condition.")
simbiologyExpressionStrings = string(arrayfun(@char, ...
    simbiologyExpressions, ...
    'UniformOutput', false));
simbiologyRateExpressions = table(["Specific growth rate"; "Biomass formation rate"; ...
    "Substrate uptake rate"; "Product formation rate"], ...
    simbiologyExpressionStrings, ...
    ["1/hour"; "gram/(liter*hour)"; "gram/(liter*hour)"; "gram/(liter*hour)"], ...
    'VariableNames', {'Quantity', 'Expression', 'ExpectedUnits'})
simbiologyReactionRateHandoff = table(["null -> X"; "S -> null"; "null -> P"], ...
    simbiologyExpressionStrings(2:4), ...
    ["gram/(liter*hour)"; "gram/(liter*hour)"; "gram/(liter*hour)"], ...
    'VariableNames', {'Reaction', 'ReactionRate', 'ExpectedUnits'})
%[text] The handoff contract checks the symbolic side of the boundary without turning this example into a SimBiology workflow. The `ReactionRate` column contains the exact strings assigned to SimBiology reaction `ReactionRate` properties in the next section. The specific growth rate is also shown because it is often reused as a custom kinetic-law expression.
%%
%[text] ## 17. Create a compact SimBiology handoff object when available
%[text] If SimBiology is installed, create a small model object and assign the generated symbolic expressions to reaction rates. This deliberately small section checks that the symbolic handoff artifact can be represented downstream without adding a full SimBiology simulation, optimization, or fitting workflow.
hasSimBiology = (exist('sbiomodel', 'file') == 2) && license('test', 'SimBiology');
if hasSimBiology
    simbiologyModel = sbiomodel('FedBatchRateLawReuse');
    simbiologyCompartment = addcompartment(simbiologyModel, 'bioreactor', initialStateVal(4));
    simbiologyCompartment.CapacityUnits = 'liter';
    addspecies(simbiologyCompartment, 'X', initialStateVal(1), 'InitialAmountUnits', 'gram/liter');
    addspecies(simbiologyCompartment, 'S', initialStateVal(2), 'InitialAmountUnits', 'gram/liter');
    addspecies(simbiologyCompartment, 'P', initialStateVal(3), 'InitialAmountUnits', 'gram/liter');
    biomassReaction = addreaction(simbiologyModel, 'null -> X');
    substrateReaction = addreaction(simbiologyModel, 'S -> null');
    productReaction = addreaction(simbiologyModel, 'null -> P');
    biomassReaction.ReactionRate = char(simbiologyReactionRateHandoff.ReactionRate(1));
    substrateReaction.ReactionRate = char(simbiologyReactionRateHandoff.ReactionRate(2));
    productReaction.ReactionRate = char(simbiologyReactionRateHandoff.ReactionRate(3));
    for parameterIndex = 1:height(simbiologyParameterHandoff)
        parameterObject = addparameter(simbiologyModel, char(simbiologyParameterHandoff.Name(parameterIndex)), ...
            simbiologyParameterHandoff.Value(parameterIndex));
        parameterObject.ValueUnits = char(simbiologyParameterHandoff.Unit(parameterIndex));
    end
    simbiologyReactionTable = table(string({simbiologyModel.Reactions.Name})', ...
        string({simbiologyModel.Reactions.Reaction})', string({simbiologyModel.Reactions.ReactionRate})', ...
        'VariableNames', {'Name', 'Reaction', 'ReactionRate'})
else
    simbiologyReactionTable = simbiologyReactionRateHandoff
end
%[text] The same symbolic rate law is now visible as MATLAB generated functions, local state-space models, and SimBiology reaction-rate strings. One reviewed symbolic derivation feeds multiple downstream consumers.
%%
%[text] ## 18. Generated artifact summary
%[text] Keep generated files small, unit-free, and regenerated from this Live Script when kinetic assumptions or units change.
handoffSummary = table(["bioreactorRates.m"; "fedBatchBioreactorRHS.m"; "bioreactorJacobian.m"; ...
    "bioreactorProductivity.m"; "bioreactorProductivityGradient.m"], ...
    ["Rate law and temperature sensitivity"; "ODE RHS used by `ode15s` and reusable in Simulink or custom simulation workflows"; ...
    "State/input Jacobians used above for trajectory perturbation analysis and Control System Toolbox state-space models"; ...
    "Algebraic product formation rate used for local trade studies"; "Analytic substrate and temperature productivity sensitivities"], ...
    'VariableNames', {'GeneratedFile', 'DownstreamUse'})
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
