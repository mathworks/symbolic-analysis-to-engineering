function [selection, standardOrifices] = selectStandardOrifice(requiredAreaIn2, margin)
%SELECTSTANDARDORIFICE Select a representative standard relief-valve orifice.
%   SELECTION = SELECTSTANDARDORIFICE(REQUIREDAREAIN2, MARGIN) chooses the
%   smallest listed orifice area that is greater than or equal to
%   REQUIREDAREAIN2*(1 + MARGIN). The table is representative for teaching
%   only and must be verified against the governing standard before design use.
arguments
    requiredAreaIn2 (:,1) double {mustBeNonnegative}
    margin (1,1) double {mustBeNonnegative} = 0
end
labels = ["D";"E";"F";"G";"H";"J";"K";"L";"M";"N";"P";"Q";"R";"T"];
areasIn2 = [0.110;0.196;0.307;0.503;0.785;1.287;1.838;2.853;3.600;4.340;6.380;11.050;16.000;26.000];
standardOrifices = table(labels,areasIn2,'VariableNames',{'Orifice','Area_in2'});
targetAreaIn2 = requiredAreaIn2.*(1 + margin);
nAreas = numel(requiredAreaIn2);
selectedLabel = strings(nAreas,1);
selectedAreaIn2 = nan(nAreas,1);
for idx = 1:nAreas
    selectedIdx = find(areasIn2 >= targetAreaIn2(idx),1,'first');
    if isempty(selectedIdx)
        selectedLabel(idx) = "No listed size";
    else
        selectedLabel(idx) = labels(selectedIdx);
        selectedAreaIn2(idx) = areasIn2(selectedIdx);
    end
end
selection = table(requiredAreaIn2,targetAreaIn2,selectedLabel,selectedAreaIn2,selectedAreaIn2./requiredAreaIn2 - 1,'VariableNames',{'RequiredArea_in2','TargetArea_in2','Orifice','StandardArea_in2','InstalledMargin'});
end
