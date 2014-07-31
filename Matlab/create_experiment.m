% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

% Creates a set of setup files based on a configuration and experiment
% definition.
function create_experiment()

    %% SPECIFY CONFIGURATION AND EXPERIMENT
%     configuration_input = 'input/configurations/weiss_initial.yaml';
%     experiment_input = 'input/experiments/weiss/2014-07-01-all-households.yaml';
    configuration_input = 'input/configurations/kolter_initial.yaml';
    experiment_input = 'input/experiments/kolter/default.yaml';

    % load values of configuration and experiment
    configuration = ReadYaml(configuration_input);
    configuration_name = configuration.configuration_name;
    experiment = ReadYaml(experiment_input);
    experiment_name = cell2mat(experiment.experiment_name);
    folder_setup_files = ['input/autogen/experiments/', experiment_name, '/'];

    % prepare experiment struct
    field_names = fieldnames(configuration);
    experiment_parameters = {};
    experiment_values = {};
    for field_name = field_names'
        % if field is specified in experiment (and is not empty):
        % use these values instead of the values from the configuration
        if isfield(experiment, field_name) && ~isempty(experiment.(field_name{1}))
            values = experiment.(field_name{1});
            if length(values) == 1
                setup.(field_name{1}) = cell2mat(values);
            else
                experiment_parameters{end+1} = field_name{1};
                experiment_values{end+1} = values;
            end
        
        % Otherwise: Use the value from the default configuration
        else
            value = configuration.(field_name{1});
            if isempty(value) || iscell(value)
                error('Ecactly one value must be specified in the default configuration (not a cell).');
            end
            setup.(field_name{1}) = value;
        end
    end
    
    % set other setup parameters
    setup.configuration = configuration_name;
    setup.experiment = experiment_name;
    
    create_setup_files(experiment_parameters, experiment_values, setup, '', 1, folder_setup_files) 

% path_to_experiment_results = strcat('results/', algorithm, '_', configuration, '/', experiment_name); 

    