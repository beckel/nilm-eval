% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [] = run_experiment(algorithm, configuration, experiment)

    % run an experiment

    % load setup files
    path_to_experiment_folder = strcat('input/autogen/experiments/setups/', algorithm, '_', configuration, '/', experiment, '/*.yaml');
    folder_content = dir(path_to_experiment_folder);
    
    % iteratively run the algorithm with each setup file
    for i = 1:length(folder_content)
        setup_file = folder_content(i).name;
        path_to_setup_file = strcat('input/autogen/experiments/setups/', algorithm, '_', configuration, '/', experiment, '/', setup_file);
        eval_system(path_to_setup_file);
    end

end

