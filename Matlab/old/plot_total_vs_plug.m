% Define parameters
house = 2;
interval = 1;
appliance = 4;
maxNumOfDays = 10;

%dates = getDates(house, appliance, maxNumOfDays,1);
dates = ['2012-06-03'; '2012-06-04'];

% Read power data from file(s)
total_power = read_smartmeter_data(num2str(house, '%02d'), dates, interval, 'powerl1');
appliance_consumption = read_plug_data(house, appliance, dates, interval);

% Get new start and end dates from data (in case we gave wrong ones)
start_date = dates(1,:);
end_date = dates(end,:);
numDays = size(dates,1);

% Create new figure
f = figure();
% Build x tics (time from midnight to midnight)
startDate = datenum(strcat(start_date, ' 00:00:00'));
endDate = datenum(strcat(end_date, ' 24:00:00'));
timeTics = linspace(startDate,endDate,numDays*86400/interval);
% Plot schedule
plot(timeTics, appliance_consumption, 'r');
% Formatting...
datetick('x', 'HH:MM');
ylabel('Power [W]');
xlabel('Time of day');
legend('Total Power', 'Plug');
grid on;
title({'Total Power Consumption vs Plug Power Consumption', sprintf('%s to %s (House: %i) ', start_date, end_date, house)});

axis tight;


