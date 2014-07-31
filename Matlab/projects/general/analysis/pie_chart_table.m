% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

%params
dataset = 'thun';
households = [1,2,3,4,5,6];
evalDays_type = 'completeSM-first90';
granularity = 1;

power_pct = {};
existing = {};
for h = 1:length(households)
    house = households(h);
    path_to_evalDays = strcat(pwd, '/input/evaluation_days/', dataset, '/', evalDays_type, '/', num2str(house, '%02d'), '.mat');
    load(path_to_evalDays); % evalDays

    % total consumption
    smartmeter_consumption = read_smartmeter_data(dataset, house, evalDays, granularity, 'powerallphases');
    missing_values_idx_sm = smartmeter_consumption == -1; 
    total_consumption = sum(smartmeter_consumption(~missing_values_idx_sm));

    % consumption of each appliance
    appliances = findAppliances(house, 'eco');
    for appliance = appliances
       plug_consumption = read_plug_data(dataset, house, appliance, evalDays, granularity);
       missing_values_idx_plug = plug_consumption == -1;
       sum_plug_consumption = sum(plug_consumption(~missing_values_idx_plug));
       ratio = nnz(~missing_values_idx_sm) / nnz(~missing_values_idx_plug);
       extrapolated_plug_consumption = ratio*sum_plug_consumption;
       power_pct{appliance, h} = strcat(num2str(100*extrapolated_plug_consumption / total_consumption, '%.0f'), ' \%');
       existing{appliance, h} = strcat(num2str(100*nnz(~missing_values_idx_plug) / nnz(~missing_values_idx_sm), '%.0f'), ' \%');
    end

    %power_pct{18,h} = sum(power_pct(~isnan(power_pct(:,h)),h));
end

rowLabels = {'Fridge', 'Freezer', 'Microwave', 'Dishwasher', 'Entertainment',...
        'Water kettle', 'Stove', 'Coffee machine', 'Washing machine', 'Dryer', 'Lamp', 'PC', 'Laptop', 'TV', 'Stereo', 'Tablet', 'Router'};
columnLabels = {'House 1', 'House 2', 'House 3', 'House 4', 'House 5', 'House 6'};
matrix2latex(power_pct, 'dataset.tex', 'rowLabels', rowLabels, 'columnLabels', columnLabels, 'format', '%.0f');
matrix2latex(existing, 'dataset2.tex', 'rowLabels', rowLabels, 'columnLabels', columnLabels, 'format', '%0.2f');
