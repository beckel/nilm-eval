% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [] = create_experiment(algorithm, configuration, experiment_name)

    % create a new experiment

    % load values of default configuration
    path_to_configuration = strcat('input/autogen/configurations/', algorithm, '_', configuration);
    load(strcat(path_to_configuration, '/default_values.mat'));
    
    % load values of experiment 
    yaml_file = strcat('input/yaml/', algorithm, '.yaml');
    experiment = ReadYaml(yaml_file);
        
    % get experiment parameters
    setup = default;
    experiment_parameters = {};
    experiment_values = {};
    field_names = fieldnames(experiment);
    for field_name = field_names'
        values = experiment.(field_name{1});
        if length(values) == 1
            setup.(field_name{1}) = cell2mat(values(1));
        end
        if length(values) > 1
            experiment_parameters{end+1} = field_name{1};
            experiment_values{end+1} = values;
        end
    end
    
    % set experiment name if none is provided
    experiment_parameters_str = strjoin(experiment_parameters, '_');
    if isempty(experiment_parameters_str)
        experiment_parameters_str = 'default';
    end    
    if nargin < 3 || isempty(experiment_name)
        experiment_name = experiment_parameters_str;
    end

    % create folder to store the setup files
    path_to_experiment_setups = strcat('input/autogen/experiments/setups/', algorithm, '_', configuration, '/', experiment_name);
    path_to_experiment_results = strcat('results/', algorithm, '_', configuration, '/', experiment_name); 
    if exist(path_to_experiment_setups) || exist(path_to_experiment_results)
       error('set a unique experiment name or extend an existing experiment') 
    end
    mkdir(path_to_experiment_setups);
    
    % set name of algorithm, name of default configuration and experiment
    % name
    setup.algorithm = algorithm;
    setup.configuration = configuration;
    setup.experiment = experiment_name;
    
    % create the setup files
    create_setup_files(experiment_parameters, experiment_values, setup, '', 1, path_to_experiment_setups) 
    
    % store the yaml file that defines the experiment
    path_to_experiment_yaml = strcat('input/autogen/experiments/yaml/', algorithm, '_', configuration);
    mkdir(path_to_experiment_yaml);
    copyfile(yaml_file, strcat(path_to_experiment_yaml, '/', experiment_name, '.yaml'));

end

