function [snrDb, receivedPowerDbm, lossDiffDb, lossBudgetDb] = radarLinkBudget( ...
    slantRange, lambda, transmitPowerDbm, antennaGainDb, targetRcsDbsm, noiseFloorDbm, nu)
%radarLinkBudget Two-way monostatic radar link budget with knife-edge diffraction.
%   [snrDb, receivedPowerDbm, lossDiffDb, lossBudgetDb] = radarLinkBudget( ...
%       slantRange, lambda, transmitPowerDbm, antennaGainDb, targetRcsDbsm, noiseFloorDbm, nu)
%   computes received power and SNR in dB using the generated
%   knifeEdgeDiffractionKernels function. slantRange is one-way range in
%   meters. targetRcsDbsm, slantRange, and nu may be scalar or compatible
%   arrays. lossBudgetDb is one-way diffraction loss; receivedPowerDbm
%   applies 2*lossBudgetDb for the outbound and return propagation paths.

arguments
    slantRange {mustBeNumeric, mustBePositive}
    lambda {mustBeNumeric, mustBePositive}
    transmitPowerDbm {mustBeNumeric}
    antennaGainDb {mustBeNumeric}
    targetRcsDbsm {mustBeNumeric}
    noiseFloorDbm {mustBeNumeric}
    nu {mustBeNumeric}
end

[~, lossDiffDb] = knifeEdgeDiffractionKernels(nu);
lossBudgetDb = max(lossDiffDb, 0);

receivedPowerDbm = transmitPowerDbm + 2*antennaGainDb + targetRcsDbsm + ...
    20*log10(lambda) - 30*log10(4*pi) - 40*log10(slantRange) - 2*lossBudgetDb;
snrDb = receivedPowerDbm - noiseFloorDbm;
end
