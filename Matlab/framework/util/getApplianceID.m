% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [applianceID] = getApplianceID(applianceName)

    % returns the ID of an appliance

    cellWithAllApplianceNames = getCellWithAllApplianceNames();
    applianceID = find(strcmpi(cellWithAllApplianceNames, applianceName));

end

