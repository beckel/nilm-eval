% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Christian Beckel;

clear;

household = 2;
dataset = 'thun';
evalDays_type = 'all';
granularity = 1;

path_to_evalDays = strcat(pwd, '/input/evaluation_days/', dataset, '/', evalDays_type, '/', num2str(household, '%02d'), '.mat');
load(path_to_evalDays); % evalDays

   % smartmeter_consumption = read_smartmeter_data(dataset, household, evalDays, granularity, 'powerallphases');
   % missing_values_idx_sm = smartmeter_consumption == -1; 
   % total_consumption = sum(smartmeter_consumption(~missing_values_idx_sm));

% consumption of each appliance
appliances = findAppliances(household, dataset);

% 1: fridge
% 2: freezer

consumption_fridge = read_plug_data(dataset, household, 1, evalDays, granularity);
consumption_freezer = read_plug_data(dataset, household, 2, evalDays, granularity);

both_valid = consumption_fridge > -1 & consumption_freezer > -1;

fridge_running = consumption_fridge > 30 & both_valid;
freezer_running = consumption_freezer > 30 & both_valid;
only_fridge_running = consumption_fridge > 30 & consumption_freezer < 30 & both_valid;
both_running = consumption_fridge > 30 & consumption_freezer > 30 & both_valid;

fprintf('fraction (each time instant)\n');
frac_both_running = sum(both_running) / sum(both_valid)
frac_only_fridge_running = sum(only_fridge_running) / sum(both_valid)

i = 1;
num_only_fridge = 0;
num_interrupted = 0;
while i < length(fridge_running)
    duration = 0;
    if fridge_running(i) == 0 && fridge_running(i+1) == 1
        i = i+1;
        is_only_fridge_running = 1;
        while (fridge_running(i) == 1 && fridge_running(i+1) == 1)
            i = i+1;
            if ~only_fridge_running(i) == 1 
                is_only_fridge_running = 0;
                break;
            end
            
            if i == length(fridge_running)
                break;
            end
        end
    
        if is_only_fridge_running == 1
            num_only_fridge = num_only_fridge + 1
        else
            num_interrupted = num_interrupted + 1
        end
    end
    i = i+1;
end

fprintf('Only fridge: %d, interrupted: %d, total: %d, fraction: %d\n', num_only_fridge, num_interrupted, num_only_fridge+num_interrupted, num_only_fridge/(num_only_fridge+num_interrupted));



%plot(consumption_fridge(870000:880000), 'Color', 'r');
%hold on;
%plot(consumption_freezer(870000:880000), 'Color', 'k');

