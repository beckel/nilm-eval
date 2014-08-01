% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function run_experiment()

    %% SPECIFY CONFIGURATION AND EXPERIMENT
    configuration_input = 'input/configurations/parsonAppliance_initial.yaml';
    experiment_input = 'input/experiments/parson/parsonAppliance_fridge.yaml';
    
    configuration = ReadYaml(configuration_input);
    algorithm = configuration.algorithm;
    experiment = ReadYaml(experiment_input);
    experiment_name = cell2mat(experiment.experiment_name);
    
    experiment_folder = ['input/autogen/experiments/', algorithm, '/', experiment_name, '/'];
    
    % iteratively run NILM-Eval for each setup file
    setup_files = dir([experiment_folder, '*.yaml']);
    for i = 1:length(setup_files)
        setup_file = setup_files(i).name;
        nilm_eval([experiment_folder, setup_file]);
    end
    
    summarize_results(configuration, experiment)
            
end
