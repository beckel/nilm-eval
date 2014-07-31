% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function run_experiment()

    experiment_folder = 'input/autogen/experiments/baranski_default/';
    
    % iteratively run NILM-Eval for each setup file
    setup_files = dir([experiment_folder, '*.yaml']);
    for i = 1:length(setup_files)
        setup_file = setup_files(i).name;
        nilm_eval([experiment_folder, setup_file]);
    end
end
