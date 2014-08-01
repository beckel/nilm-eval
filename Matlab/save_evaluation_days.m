% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

% Stores the evaluation days of a household in 'input/evaluation_days/{dataset}/{name}/{household}.mat'
% These files are later on used by the evaluation system to read the smart
% meter and plug data. The name {name} must be specified in the
% corresponding config file.

function save_evaluation_days()
    
    %% CONFIG HERE (name of the evaluation_day file)
    config_file = 'input/evaluation_days/all.yaml';
    
    config = ReadYaml(config_file);
    
    name = config.name;
    dataset = config.dataset;
    houses = config.houses;
    maxNumOfDays = config.maxNumOfDays;
    startDate = config.startDate;
    endDate = config.endDate;
    % If the proportion of missing values on a specific day D is higher than missingValuesThresholdSM, D is not included in the set of evaluation days.
    missingValuesThresholdSM = config.missingValuesThresholdSM; 
    % If the proportion of missing values for any of the plugs on a specific day D is higher than missingValuesThresholdPlug, D is not included in the set of evaluation days.
    missingValuesThresholdPlug = config.missingValuesThresholdPlug; 

    for h = 1:length(houses)
        house = houses{h};
        fprintf('Processing house %d\n', house);
        evalDays = getDates(house, maxNumOfDays, missingValuesThresholdSM, missingValuesThresholdPlug, dataset, startDate, endDate);    
        path_to_evalDays = strcat(pwd, '/input/autogen/evaluation_days/', dataset, '/', name);
        if ~exist(path_to_evalDays, 'dir')
            mkdir(path_to_evalDays);
        end
        filename_dates = strcat(path_to_evalDays, '/', num2str(house, '%02d'), '.mat');
        save(filename_dates, 'evalDays');
    end
end

