% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [usedParameterValues] = updateEventMetrics(usedParameterValues, summary)

    % update event metrics in 'usedParametervalues'
    
    for event_metric = fieldnames(summary.events)'
       if (~ismember(event_metric{1}, usedParameterValues.event_metrics))
            metrics_cell = usedParameterValues.event_metrics;
            metrics_cell{length(metrics_cell)+1} = event_metric{1};
            usedParameterValues.event_metrics = metrics_cell;
       end              
    end

end

