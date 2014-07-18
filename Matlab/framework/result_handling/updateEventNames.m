% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [usedParameterValues] = updateEventNames(usedParameterValues, summary)

    % update event names in 'usedParametervalues'

    for s = 1:length(summary.event_names)
        param_value = summary.event_names{s};
        if iscell(param_value)
            param_value = param_value{1};
        end
        if (~ismember(param_value, usedParameterValues.event_names))
            events_cell = usedParameterValues.event_names;
            events_cell{length(events_cell)+1} = param_value;
            usedParameterValues.event_names = events_cell;
        end
    end

end

