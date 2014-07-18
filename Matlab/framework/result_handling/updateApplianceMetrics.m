% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [usedParameterValues] = updateApplianceMetrics(usedParameterValues, summary)

    % update appliance metrics in 'usedParametervalues'

    for appliance_metric = fieldnames(summary.consumption)'
       if (~ismember(appliance_metric{1}, usedParameterValues.appliance_metrics))
            metrics_cell = usedParameterValues.appliance_metrics;
            metrics_cell{length(metrics_cell)+1} = appliance_metric{1};
            usedParameterValues.appliance_metrics = metrics_cell;
       end              
    end

end

