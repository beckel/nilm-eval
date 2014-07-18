% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [names] = getApplianceNames(appliances)

    % returns the names of the specified appliances

    cellWithAllApplianceNames = getCellWithAllApplianceNames();
    names = cell(1,length(appliances));
    for i = 1:length(appliances)
        names{i} = cell2mat(cellWithAllApplianceNames(appliances(i)));
    end

end

