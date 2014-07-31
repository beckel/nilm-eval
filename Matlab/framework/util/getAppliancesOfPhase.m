% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [ appliances ] = getAppliancesOfPhase(dataset, household, phase)

    % returns all appliances of a household that run on the specified phase

    phase_matrix = getPhaseMatrix(dataset);         
    appliances = find(phase_matrix(:,household) == phase);

end

