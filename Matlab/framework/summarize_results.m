% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

% saves the results (fscore, rms, etc.) of an experiment in the
% 'experiment_result' structure

function [] = summarize_results(configuration, experiment)

    configuration_name = configuration.configuration_name;
    experiment_name = cell2mat(experiment.experiment_name);
    algorithm = configuration.algorithm;

    is_multiple_value_experiment = 0;
    
    % get experiment parameters
    experiment_parameters = {};
    field_names = fieldnames(experiment);
    for field_name = field_names'
        values = experiment.(field_name{1});
        if length(values) > 1
            experiment_parameters{end+1} = field_name{1};
            is_multiple_value_experiment = 1;
        end
    end

    if is_multiple_value_experiment == 1
        % get all experiment instances    
        results_folder = strcat('results/summary/', algorithm, '/', configuration_name, '/', experiment_name);
        content_of_results_folder = dir(results_folder);
        idx_subdirectories = [content_of_results_folder(:).isdir];
        experiment_instances = {content_of_results_folder(idx_subdirectories).name};
        experiment_instances(ismember(experiment_instances,{'.','..'})) = [];

        % create or update 'usedParameterValues.mat' file. This file contains all values of each experiment parameter
        saveUsedParameterValues(experiment_parameters, results_folder, experiment_instances);
        load(strcat(results_folder, '/parameters.mat'));

        % store results
        experiment_result = struct;
        idx_param_values = zeros(1, length(experiment_parameters));
        for i = 1:length(experiment_instances)   
            % get index of experiment instance in 'experiment_result' so that the
            % results are stored at the right place
            param_values = strsplit('_', experiment_instances{i});        
            for j = 1:length(param_values)
                idx_param_values(j) = find(ismember(parameters.(experiment_parameters{j}), strrep(param_values{j}, '-', '.')));
            end

            path_to_experiment_instance = strcat(results_folder, '/', experiment_instances{i});
            if exist(strcat(path_to_experiment_instance, '/summary.mat'), 'file')
                load(strcat(path_to_experiment_instance, '/summary.mat')); 
                % store results of inferred events
                if ~isempty(parameters.event_names)
                    for j = 1:length(summary.event_names)
                        event_name_idx = find(ismember(parameters.event_names,summary.event_names{j}));
                        for function_idx = 1:length(parameters.combine_results) 
                            function_handle = str2func(parameters.combine_results{function_idx});
                            for metric_idx = 1:length(parameters.event_metrics)
                                metric = parameters.event_metrics{metric_idx};
                                idx_cell = num2cell([idx_param_values, event_name_idx, function_idx, metric_idx]);
                                experiment_result.events(idx_cell{:}) = function_handle(summary.events.(metric)(j,:));
                            end
                        end
                    end
                end
                % store results of inferred appliance consumption
                if ~isempty(parameters.appliance_names)
                    for j = 1:length(parameters.appliance_names)
                        appliance_name_idx = find(ismember(parameters.appliance_names, summary.appliance_names{j}));
                        for function_idx = 1:length(parameters.combine_results)
                            function_handle = str2func(parameters.combine_results{function_idx});
                            for metric_idx = 1:length(parameters.appliance_metrics)
                                metric = parameters.appliance_metrics{metric_idx};
                                idx_cell = num2cell([idx_param_values, appliance_name_idx, function_idx, metric_idx]); 
                                experiment_result.consumption(idx_cell{:}) = function_handle(summary.consumption.(metric)(j,:));
                            end
                        end
                    end
                end
                clear summary;
            end
        end
        save(strcat(results_folder, '/experiment_result.mat'), 'experiment_result');
    end
end

