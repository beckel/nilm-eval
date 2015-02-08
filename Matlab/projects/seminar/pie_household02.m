% load all result variables

width = 24;
height = 12;
fontsize = 9;
plot_filename = 'pie_household_02';
plot_folder = 'projects/seminar/';

experiments = {'app_dishwasher_r_0.1', ...
                'app_freezer_r_0.2', ...
                'app_fridge_r_0.1', ...
                'app_kettle_r_0.1', ...
                'app_stereo_r_0.2', ...
                'app_stove_r_1', ...
                'app_tv_r_0.2', ...
            };
        
inferred = zeros(1, length(experiments) + 4);
actual = zeros(1, length(experiments) + 3);
appliance_names = {};
for i = 1:length(experiments)
    experiment = experiments{i};
    
    filename = ['results/details/weiss/weiss_initial/', experiment, '/default/result1.mat'];
    load(filename);
    setup = result.setup;
    household = setup.household;
    dataset = setup.dataset;
    granularity = setup.granularity;
    
    appliance_name = result.appliance_names{1};
    appliance_names = [appliance_names, appliance_name];
    % inferred consumption
    inferred(i) = sum(result.consumption) / 3600;
    
    evaluation_days = result.evaluation_and_training_days{1};
    appliance_id = getApplianceID(appliance_name);
    appliance_consumption = read_plug_data(dataset, ...
                                    household, ...
                                    appliance_id, ...
                                    evaluation_days, ...
                                    granularity);
    actual_valid = appliance_consumption ~= -1;
    percentage_valid = sum(actual_valid) / length(appliance_consumption);
    actual(i) = sum(appliance_consumption(actual_valid)) / 3600 / percentage_valid;
end

total_consumption = read_smartmeter_data(dataset, ...
                                    num2str(household, '%02d'), ...
                                    evaluation_days, ...
                                    granularity, ...
                                    'powerallphases');

%% Laptop
num_days = size(evaluation_days,1);
laptop = num_days * 40 * 4;
idx = length(experiments) + 1;
inferred(idx) = laptop;
appliance_id = getApplianceID('Laptop');
appliance_consumption = read_plug_data(dataset, ...
                                household, ...
                                appliance_id, ...
                                evaluation_days, ...
                                granularity);
actual_valid = appliance_consumption ~= -1;
percentage_valid = sum(actual_valid) / length(appliance_consumption);
actual(idx) = sum(appliance_consumption(actual_valid)) / 3600 / percentage_valid;
appliance_names{idx} = 'Laptop';

%% Lamp
lamp = num_days * 100 * 1;
idx = length(experiments) + 2;
inferred(idx) = lamp;
appliance_id = getApplianceID('Lamp');
appliance_consumption = read_plug_data(dataset, ...
                                household, ...
                                appliance_id, ...
                                evaluation_days, ...
                                granularity);
actual_valid = appliance_consumption ~= -1;
percentage_valid = sum(actual_valid) / length(appliance_consumption);
actual(idx) = sum(appliance_consumption(actual_valid)) / 3600 / percentage_valid;
appliance_names{idx} = 'Lamp';

%% Standby
num_days = size(evaluation_days,1);
min_cons = zeros(1,num_days);
for i = 1:num_days
    % 1 p.m. to 5 p.m.
    idx_start = (i-1)*86400 + 1*3600;
    idx_stop = (i-1)*86400 + 5*3600;
    min_cons(i) = min(total_consumption(idx_start:idx_stop));
end
standby = median(min_cons) * length(total_consumption) / 3600;
inferred(length(experiments) + 3) = standby;
appliance_names_inferred = appliance_names;
appliance_names_inferred{length(experiments) + 3} = 'Standby';

%% Other
other_inferred = sum(total_consumption) / 3600 - sum(inferred);
inferred(length(experiments) + 4) = other_inferred;
other_actual = sum(total_consumption) / 3600 - sum(actual);
actual(length(experiments) + 3) = other_actual;
appliance_names_inferred{length(experiments)+4} = 'Other';
appliance_names{length(experiments)+3} = 'Other';

%% Change TV and Laptop for better plotting
tmp = appliance_names(7);
appliance_names(7) = appliance_names(8);
appliance_names(8) = tmp;
tmp = appliance_names_inferred(7);
appliance_names_inferred(7) = appliance_names_inferred(8);
appliance_names_inferred(8) = tmp;
tmp = actual(7);
actual(7) = actual(8);
actual(8) = tmp;
tmp = inferred(7);
inferred(7) = inferred(8);
inferred(8) = tmp;

%% Save as csv file
fid = fopen([plot_folder, 'actual.csv'], 'w');
fprintf(fid, 'label,consumption,share\n');
for i = 1:length(actual)
    fprintf(fid, '%s, %.2f, %.3f\n', appliance_names{i}, actual(i)/1000, actual(i) / sum(actual));
end
fclose(fid);
fid = fopen([plot_folder, 'inferred.csv'], 'w');
fprintf(fid, 'label,consumption,share\n');
for i = 1:length(inferred)
    fprintf(fid, '%s, %.2f, %.3f\n', appliance_names_inferred{i}, inferred(i)/1000, inferred(i) / sum(inferred));
end
fclose(fid);


% 
% fig = figure;
% hold on;
% subplot(1,2,1);
% pie(actual);
% title('Ground truth');
% subplot(1,2,2);
% pie(inferred);
% labels = appliance_names_inferred;
% legend(labels);
% title('Inferred');
% fig = make_report_ready(fig, 'size', [width, height], 'fontsize', fontsize);    
% % print('-depsc2', '-cmyk', '-r600', [plot_folder, filename, '.eps']); % if eps is needed
% saveas(fig, [plot_folder, plot_filename, '.png'], 'png');
% close(fig);
