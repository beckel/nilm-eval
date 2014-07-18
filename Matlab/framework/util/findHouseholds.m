% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [ houses ] = findHouseholds(appliance, dataset)

    % returns all household for which the plug-level data of the specified
    % appliance exists

     appliance_house_matrix = getApplianceHouseMatrix(dataset);
     houses = find(appliance_house_matrix(appliance,:)>0);

end

