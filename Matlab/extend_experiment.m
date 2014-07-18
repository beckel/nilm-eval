% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [] = extend_experiment(algorithm, configuration, experiment)

    % extend an existing experiment

    % load values of the default configuration
    % load values of the experiment
    path_to_experiment_yaml = strcat('input/autogen/experiments/yaml/', algorithm, '_', configuration);
    path_to_experiment_setups = strcat('input/autogen/experiments/setups/', algorithm, '_', configuration, '/', experiment);
    path_to_configuration = strcat('input/autogen/configurations/', algorithm, '_', configuration);
    yaml_experiment = strcat(path_to_experiment_yaml,'/', experiment, '.yaml');
    experiment_extended = ReadYaml(yaml_experiment);
    load(strcat(path_to_configuration, '/default_values.mat'));
    
    % set the experiment parameters
    experiment_parameters = {};
    experiment_values = {};
    field_names = fieldnames(experiment_extended);
    for field_name = field_names'
        values = cell2mat(experiment_extended.(field_name{1}));
        if length(values) >= 1
            experiment_parameters{end+1} = field_name{1};
            experiment_values{end+1} = values;
        end
    end

    % set the name of the algorithm, the name of the experiment and the
    % name of the default configuration
    setup = default;
    setup.algorithm = algorithm;
    setup.configuration = configuration;
    setup.experiment = experiment;
    
    % create the setup files
    create_setup_files(experiment_parameters, experiment_values, setup, '', 1, path_to_experiment_setups) 

end

