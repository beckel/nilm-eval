% load all result variables

% inferred consumption
% day = 2; % 2013-07-04
% day = 11% second half
% day = 13; % second half
% day = 16; %

% day = 2;
% plot_title = '04 July 2013, Household 02';
% plot_filename = 'area_2013_07_04';
% start_on_day = 0/24 * 86400 + 1;
% stop_on_day = 24/24 * 86400;
% num_values = stop_on_day - start_on_day + 1;

% day = 11;
% plot_title = '13 July 2013, Household 02';
% plot_filename = 'area_2013_07_13';
% start_on_day = 16/24 * 86400 + 1;
% stop_on_day = 24/24 * 86400;
% num_values = stop_on_day - start_on_day + 1;

% day = 13;
% plot_title = '15 July 2013, Household 02';
% plot_filename = 'area_2013_07_15';
% start_on_day = 16/24 * 86400 + 1;
% stop_on_day = 24/24 * 86400;
% num_values = stop_on_day - start_on_day + 1;

% day = 13;
% plot_title = 'Night of 15 July 2013, Household 02';
% plot_filename = 'area_2013_07_15_night';
% start_on_day = 0/24 * 86400 + 1;
% stop_on_day = 6/24 * 86400;
% num_values = stop_on_day - start_on_day + 1;

% day 8 not so good
% day 6 even worse
day = 8;
plot_title = '10 July 2013, Household 02';
plot_filename = 'area_2013_07_10_bad';
start_on_day = 12/24 * 86400 + 1;
stop_on_day = 24/24 * 86400;
num_values = stop_on_day - start_on_day + 1;

% day = 16;
% plot_title = '20 July 2013, Household 02';
% plot_filename = 'area_2013_07_20';
% start_on_day = 0/24 * 86400 + 1;
% stop_on_day = 24/24 * 86400;
% num_values = stop_on_day - start_on_day + 1;

width = 16;
height = 12;
fontsize = 9;
plot_folder = 'projects/seminar/';

experiments = {'app_tv_r_0.2', ...
                'app_stereo_r_0.2', ...
                'app_kettle_r_0.1', ...
                'app_stove_r_1', ...
                'app_dishwasher_r_0.1', ...
                'app_freezer_r_0.2', ...
                'app_fridge_r_0.1', ...
            };
        
inferred = zeros(length(experiments), num_values);
actual = zeros(length(experiments) + 1, num_values);

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

    idx_start = (day-1) * 86400 + start_on_day;
    idx_stop = (day-1) * 86400 + stop_on_day;
    inferred(i,:) = result.consumption(idx_start:idx_stop);
    
    evaluation_days = result.evaluation_and_training_days{1};
    appliance_id = getApplianceID(appliance_name);
    appliance_consumption = read_plug_data(dataset, ...
                                    household, ...
                                    appliance_id, ...
                                    evaluation_days, ...
                                    granularity);
    actual(i,:) = appliance_consumption(idx_start:idx_stop);
end

total_consumption = read_smartmeter_data(dataset, ...
                                    num2str(household, '%02d'), ...
                                    evaluation_days, ...
                                    granularity, ...
                                    'powerallphases');
total_consumption_day = total_consumption(idx_start:idx_stop);
% 
% 
% %% Laptop
% num_days = size(evaluation_days,1);
% laptop = num_days * 40 * 4;
% idx = length(experiments) + 1;
% inferred(idx) = laptop;
% appliance_id = getApplianceID('Laptop');
% appliance_consumption = read_plug_data(dataset, ...
%                                 household, ...
%                                 appliance_id, ...
%                                 evaluation_days, ...
%                                 granularity);
% actual_valid = appliance_consumption ~= -1;
% percentage_valid = sum(actual_valid) / length(appliance_consumption);
% actual(idx) = sum(appliance_consumption(actual_valid)) / 3600 / percentage_valid;
% appliance_names{idx} = 'Laptop';
% 
% %% Lamp
% lamp = num_days * 100 * 1;
% idx = length(experiments) + 2;
% inferred(idx) = lamp;
% appliance_id = getApplianceID('Lamp');
% appliance_consumption = read_plug_data(dataset, ...
%                                 household, ...
%                                 appliance_id, ...
%                                 evaluation_days, ...
%                                 granularity);
% actual_valid = appliance_consumption ~= -1;
% percentage_valid = sum(actual_valid) / length(appliance_consumption);
% actual(idx) = sum(appliance_consumption(actual_valid)) / 3600 / percentage_valid;
% appliance_names{idx} = 'Lamp';

%% Standby
num_days = size(evaluation_days,1);
min_cons = zeros(1,num_days);
for i = 1:num_days
    % 1 p.m. to 5 p.m.
    idx_start_night = (i-1)*86400 + 1*3600;
    idx_stop_night = (i-1)*86400 + 5*3600;
    min_cons(i) = min(total_consumption(idx_start_night:idx_stop_night));
end
standby = median(min_cons);
inferred = [ ones(1,num_values) * standby; inferred];
appliance_names_inferred = ['Standby', appliance_names];

%% Other
other_inferred = total_consumption_day - sum(inferred,1);
other_actual = total_consumption_day - sum(actual,1);

%% plot
fig = figure;

xvals = datenum(evaluation_days(day,:))+(idx_start:idx_stop)/86400;

plot(xvals, total_consumption_day, 'Color', 'r');
hold on;

h = area(xvals, inferred');
h(5).FaceColor = [0, 0, 0];

% dateformat: http://ch.mathworks.com/help/matlab/ref/datetick.html#btpnuk4-1

% dateFormat = 15;
dateFormat = 'HH:MM AM';
datetick('x',dateFormat);

legend(['Smart meter', appliance_names_inferred], 'Location', 'NorthWest');
title(plot_title);
ylabel('Power [W]');
xlabel('Time of day');

fig = make_report_ready(fig, 'size', [width, height], 'fontsize', fontsize);    
saveas(fig, [plot_folder, plot_filename, '.png'], 'png');
print('-depsc2', '-cmyk', '-r600', [plot_folder, plot_filename, '.eps']);
close(fig);
