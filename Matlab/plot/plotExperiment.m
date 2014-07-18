% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [] = plotExperiment()

    % plots the results of an experiment
    %
    % Parameters:
    % parameter: name of parameter on x-axis (e.g. param1 or event_metrics)
    % lines: name of lines in plot (e.g. param1 or event_metrics)

    % get algorithm and experiment name
    result_settings = ReadYaml('input/result.yaml');
    algorithm = result_settings.algorithm;
    configuration = result_settings.configuration;
    experiment_name = result_settings.experiment;
    
    % load experiment results
    path_to_experiment = strcat('results/summary/', algorithm, '/', configuration, '/', experiment_name);
    load(strcat(path_to_experiment, '/experiment_result.mat'));

    % get parameter (x-axis on plot) and restriction (some parameters are
    % restricted to specific values, e.g. only household 2 is used)
    parameter = result_settings.parameter;
    restriction = result_settings.restriction;

    % get names and values of the experiment parameters
    yaml_file_of_experiment = strcat('input/autogen/experiments/yaml/', algorithm, '_', configuration, '/', experiment_name, '.yaml');
    experiment = ReadYaml(yaml_file_of_experiment);
    experiment_parameters = {};
    field_names = fieldnames(experiment);
    for field_name = field_names'
        values = experiment.(field_name{1});
        if length(values) > 1
            experiment_parameters{end+1} = field_name{1};
        end
    end
    parameterID = find(strcmpi(parameter,experiment_parameters));
    load(strcat(path_to_experiment, '/usedParameterValues.mat'));
    parameter_values_in_cell = usedParameterValues.(parameter);
    parameter_values = cellfun(@str2double, parameter_values_in_cell);

    % get indexes of the lines in the plot
    lines = usedParameterValues.(result_settings.lines{1});
    res = zeros(length(parameter_values), length(lines));
    result = experiment_result.(result_settings.domain);
    if ~isempty(result_settings.lines{2})
        lines_idx = find(ismember(usedParameterValues.(result_settings.lines{1}), result_settings.lines{2}));
        lines = lines(lines_idx);
    else
        lines_idx = 1:length(lines);
    end
    
    % for each line, get appropriate index of result (experiment_result)
    % idx(param1, param2, ..., param_n, event/appliance_name, combine_res,
    % event/consumption_metric)
    for i = lines_idx
        idx(1:length(experiment_parameters)) = {':'};
        
        % set index of specified event/appliance name, event/consumption metric
        % and 'combine_results' (method for combining results of different training periods) 
        if strcmpi(result_settings.domain, 'events')
            idx(length(experiment_parameters)+1) = {find(ismember(usedParameterValues.event_names, result_settings.event_name))};
            idx(length(experiment_parameters)+3) = {find(ismember(usedParameterValues.event_metrics, result_settings.metric))};
        else
            idx(length(experiment_parameters)+1) = {find(ismember(usedParameterValues.appliance_names, result_settings.appliance_name))};
            idx(length(experiment_parameters)+3) = {find(ismember(usedParameterValues.appliance_metrics, result_settings.metric))};
        end
        idx(length(experiment_parameters)+2) = {find(ismember(usedParameterValues.combine_results, result_settings.combine_res))};

        % some parameters are restricted to specific values, adapt index
        % accordingly
        for k=1:length(restriction)
            param_restricted = restriction{k};
            param_restricted_name = param_restricted{1};
            param_restricted_values = param_restricted{2};
            param_restricted_idx = find(ismember(usedParameterValues.(param_restricted_name), param_restricted_values));
            index_of_restricted_parameter = getIndexOfParameterName(param_restricted_name, experiment_parameters);
            idx(index_of_restricted_parameter) = {param_restricted_idx};
        end
        
        % set index of 'lines parameter'
        index_of_lines_parameter = getIndexOfParameterName(result_settings.lines{1}, experiment_parameters);
        idx(index_of_lines_parameter) = {i};

        % get result and store it in the 'res' matrix
        for j = 1:size(result,parameterID)
            idx(parameterID) = {j};
            r = result(idx{:});
            idx2 = r ~= 0 & ~isnan(r);
            res(j,i) = sum(r(idx2)) / nnz(idx2 ~=0);
        end
    end

    % plot the result (res matrix)
    set(0, 'DefaultAxesFontSize',12)
    set(0, 'DefaultTextFontName','Times New Roman');
    figure();
    [parameter_values_sorted, sortIdx] = sort(parameter_values);
     res_sorted = res(sortIdx, :);
    plot(parameter_values_sorted, res_sorted(:,lines_idx));
    
    % set legend of plot
    if iscellstr(lines)
        legend(lines);
    else
        legend(strcat(result_settings.lines{1}, {' '}, cellstr(num2str(lines'))'));
    end

    % set labels of axises in plot
    xlabel(parameter)
    if strcmpi(result_settings.lines{1}, 'event_metrics') || strcmpi(result_settings.lines{1}, 'appliance_metrics')
        ylabel('performance')
    else
        ylabel(result_settings.metric)
    end

    % set title of plot
    %title(['Performance of ''', algorithm ,''' algorithm with ''', configuration, ''' configuration:'],'FontWeight', 'Bold');
    
    grid on;

end

