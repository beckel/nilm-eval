%params
house = 1;
maxNumberOfDays = 300;
missingValuesThresholdSM = 1;
missingValuesThresholdPlugs = 1;
interval = 1;

% total consumption
dates = getDates(house, [], maxNumberOfDays, missingValuesThresholdSM, missingValuesThresholdPlugs);
smartmeter_consumption = read_smartmeter_data(house, dates, interval);
missing_values_idx_sm = smartmeter_consumption == -1; 
total_consumption = sum(smartmeter_consumption(~missing_values_idx_sm));

% consumption of each appliance
appliances = findAppliances(house);
power_pct = zeros(length(appliances), 1);
for i = 1:length(appliances)
   dates = getDates(house, appliances(i), maxNumberOfDays, missingValuesThresholdSM, missingValuesThresholdPlugs);
   plug_consumption = read_plug_data(house, appliances(i), dates, interval);
   missing_values_idx_plug = plug_consumption == -1;
   sum_plug_consumption = sum(plug_consumption(~missing_values_idx_plug));
   ratio = nnz(~missing_values_idx_sm) / nnz(~missing_values_idx_plug);
   extrapolated_plug_consumption = ratio*sum_plug_consumption;
   power_pct(i) = extrapolated_plug_consumption / total_consumption;
end

% plot pie chart
names = getApplianceNames(appliances);
figure()
pie_handle = pie(power_pct);
handle_array = findobj(pie_handle, 'Type', 'text');
percentages = get(handle_array, 'String');
new_labels = strcat(names', percentages);
set(handle_array, {'String'}, new_labels);
