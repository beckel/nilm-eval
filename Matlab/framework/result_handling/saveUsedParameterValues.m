% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [] = saveUsedParameterValues(param_names, results_folder, experiment_instances)

    % create or update 'usedParameterValues.mat' file. This file contains all values of each experiment parameter

    % initialize usedParameterValues
    parameters = struct;
    for i = 1:length(param_names)
        parameters.(param_names{i}) = {};
    end
    parameters.appliance_names = {}; 
    parameters.appliance_metrics = {};
    parameters.event_names = {}; 
    parameters.event_metrics = {};
    parameters.combine_results = {'min', 'max', 'mean'};

    for i = 1:length(experiment_instances)
        param_values = strsplit('_', experiment_instances{i}); 
        % if a parameter value does not already exist in
        % 'usedParameterValues', add the parameter value
        for j = 1:length(param_values)
            param_value = strrep(param_values{j}, '-', '.');
            if (~ismember(param_value, parameters.(param_names{j})))
                parameters.(param_names{j}){end+1} = param_value;
            end
        end

        load(strcat(results_folder, '/', experiment_instances{1}, '/summary.mat'));
        % add all new event names and event metrics (fscore etc.) to
        % 'usedParameterValues'
        if isfield(summary, 'events')
            parameters = updateEventNames(parameters, summary);
            parameters = updateEventMetrics(parameters, summary);
        end
        % add all new appliance names and consumption metrics (rms etc.) to
        % 'usedParameterValues'
        if isfield(summary, 'consumption')
            parameters = updateApplianceNames(parameters, summary);
            parameters = updateApplianceMetrics(parameters, summary);
        end
        clear summary;
    end

    save(strcat(results_folder, '/parameters.mat'), 'parameters');
end

