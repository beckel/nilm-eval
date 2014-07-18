% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [usedParameterValues] = updateApplianceNames(usedParameterValues, summary)

    % update appliance names in 'usedParametervalues'

    for s = 1:length(summary.appliance_names)
        param_value = summary.appliance_names{s};
        if iscell(param_value)
            param_value = param_value{1};
        end
        if (~ismember(param_value, usedParameterValues.appliance_names))
            events_cell = usedParameterValues.appliance_names;
            events_cell{length(events_cell)+1} = param_value;
            usedParameterValues.appliance_names = events_cell;
        end
    end

end

