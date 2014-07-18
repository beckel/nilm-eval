% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [index] = getIndexOfParameterName(param_name, param_names)

    if strcmpi(param_name, 'event_name') || strcmpi(param_name, 'appliance_name') || strcmpi(param_name, 'appliance_names') || strcmpi(param_name, 'event_names')
        index = length(param_names) + 1;
    elseif strcmpi(param_name, 'combine_results') || strcmpi(param_name, 'combine_res') 
        index = length(param_names) + 2;   
    elseif strcmpi(param_name, 'event_metric') || strcmpi(param_name, 'appliance_metric') || strcmpi(param_name, 'appliance_metrics') || strcmpi(param_name, 'event_metrics')
        index = length(param_names) + 3;
    else
        index = find(strcmpi(param_name,param_names));
    end

end

