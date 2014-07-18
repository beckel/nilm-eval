% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [phase] = getPhase(household, applianceID, dataset)

    % returns the phase of the specified (house, appliance)-pair

    phase_matrix = getPhaseMatrix(dataset);       
    phase = phase_matrix(applianceID, household);

end

