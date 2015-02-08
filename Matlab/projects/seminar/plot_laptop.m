width = 16;
height = 12;
fontsize = 9;
plot_folder = 'projects/seminar/output/';
% filename = ['data/eco/plugs/02/09/2012-07-13.mat'];
day = '2012-07-13';
household = 02;
dataset = 'eco';
plot_title = 'Laptop consumption - 2012-07-13';
plot_filename = 'laptop-2012-07-13';
appliance_id = getApplianceID('Laptop');
granularity = 1;
appliance_consumption = read_plug_data(dataset, ...
                                household, ...
                                appliance_id, ...
                                evaluation_days, ...
                                granularity);

idx_start = 1;
idx_stop = 86400;

% total_consumption = read_smartmeter_data(dataset, ...
%                                     num2str(household, '%02d'), ...
%                                     evaluation_days, ...
%                                     granularity, ...
%                                     'powerallphases');

%% plot
if ~exist(plot_folder, 'dir')
    mkdir(plot_folder);
end
fig = figure;
xvals = datenum(day)+(idx_start:idx_stop)/86400;
plot(xvals, appliance_consumption);
% dateformat: http://ch.mathworks.com/help/matlab/ref/datetick.html#btpnuk4-1
% dateFormat = 15;
dateFormat = 'HH:MM AM';
datetick('x',dateFormat);
% legend(['Smart meter', appliance_names_inferred], 'Location', 'NorthWest');
title(plot_title);
ylabel('Power [W]');
xlabel('Time of day');
fig = make_report_ready(fig, 'size', [width, height], 'fontsize', fontsize);    
saveas(fig, [plot_folder, plot_filename, '.png'], 'png');
print('-depsc2', '-cmyk', '-r600', [plot_folder, plot_filename, '.eps']);
close(fig);
