% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

%params
dataset = 'thun';
household = 3;
evalDays_type = 'completeSM_first90';
granularity = 1;

path_to_evalDays = strcat(pwd, '/input/evalDays/', dataset, '/', evalDays_type, '/', num2str(household, '%02d'), '.mat');
load(path_to_evalDays); % evalDays

% total consumption
smartmeter_consumption = read_smartmeter_data(dataset, household, evalDays, granularity, 'powerallphases');
missing_values_idx_sm = smartmeter_consumption == -1; 
total_consumption = sum(smartmeter_consumption(~missing_values_idx_sm));

% consumption of each appliance
appliances = findAppliances(household);
power_pct = zeros(length(appliances)+1, 1);
for i = 1:length(appliances)
   plug_consumption = read_plug_data(dataset, household, appliances(i), evalDays, granularity);
   missing_values_idx_plug = plug_consumption == -1;
   sum_plug_consumption = sum(plug_consumption(~missing_values_idx_plug));
   ratio = nnz(~missing_values_idx_sm) / nnz(~missing_values_idx_plug);
   extrapolated_plug_consumption = ratio*sum_plug_consumption;
   power_pct(i) = extrapolated_plug_consumption / total_consumption;
end

power_pct(end) = 1 - sum(power_pct(~isnan(power_pct)));

% plot pie chart
names = getApplianceNames(appliances);
names{end+1} = 'Other';
figure()
%title(strcat('Household: ', num2str(household)));
pie_handle = pie(power_pct);
set(pie_handle(2:2:end),'fontsize',12);
handle_array = findobj(pie_handle, 'Type', 'text');
percentages = get(handle_array, 'String');
new_labels = strcat(names',{': '}, percentages);
set(handle_array, {'String'}, new_labels);
