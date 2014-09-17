%params
dataset = 'eco';
households = [1,2,3,4,5,6];
evalDays_type = 'plug_statistics';
granularity = 1;

existing = {};
for h = 1:length(households)
    fprintf('Household %d ... ', h);
    house = households(h);
    path_to_evalDays = strcat(pwd, '/input/autogen/evaluation_days/', dataset, '/', evalDays_type, '/', num2str(house, '%02d'), '.mat');
    load(path_to_evalDays); % evalDays

    % consumption of each appliance
    appliances = findAppliances(house, dataset);
    for appliance = appliances
        fprintf(' %d', appliance);
        plug_consumption = read_plug_data(dataset, house, appliance, evalDays, granularity);
        missing_values_idx_plug = plug_consumption == -1;
        sum_plug_consumption = sum(plug_consumption(~missing_values_idx_plug));
        existing{appliance, h} = strcat(num2str(100*nnz(~missing_values_idx_plug) / nnz(~missing_values_idx_sm), '%.0f'), ' \%');
    end

    fprintf(' done \n');
end
%% here

rowLabels = {'Fridge', 'Freezer', 'Microwave', 'Dishwasher', 'Entertainment',...
        'Kettle', 'Stove', 'Coffee machine', 'Washing machine', 'Dryer', 'Lamp', 'PC', 'Laptop(s)', 'TV', 'Stereo', 'Tablet', 'Router'};
columnLabels = {'H1', 'H2', 'H3', 'H4', 'H5', 'H6'};
out_file_name = [pwd, '/projects/buildsys/percentage.tex'];
matrix2latex(existing, out_file_name, 'rowLabels', rowLabels, 'columnLabels', columnLabels, 'format', '%0.2f');
