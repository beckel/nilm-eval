% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [ appliances ] = findAppliances(house, dataset)

    % returns all appliances of a specified household for which plug-level data
    % exists

     appliance_house_matrix = getApplianceHouseMatrix(dataset);
     appliances = find(appliance_house_matrix(:,house)>0);
     appliances = appliances';

end

