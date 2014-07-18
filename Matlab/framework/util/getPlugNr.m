% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [plug] = getPlugNr(appliance, house, dataset)

    % returns the plug nr of a specified (appliance, house, dataset)-triple

    appliance_house_matrix = getApplianceHouseMatrix(dataset);   
    plug = num2str(appliance_house_matrix(appliance, house), '%02d');

end

