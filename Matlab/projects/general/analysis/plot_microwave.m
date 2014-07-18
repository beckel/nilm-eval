% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

% parameters
dataset = 'thun';
granularity = 60;
houses = [5];
appliance_name = 'microwave';
dates = ['2012-07-11'];
start_date = '2012-07-11';
end_date = '2012-07-11';
consumptionArray = zeros((24*60*60)/granularity,5);

% obtain consumption data
appliance_id =  getApplianceID(appliance_name);
numOfDaysPerHousehold = zeros(length(houses), 1);
counter = 0;
for house = houses
    consumption = read_plug_data(dataset, house, appliance_id, dates, granularity );
    counter = counter + 1;
    consumptionArray(1:length(consumption),counter) = consumption;
end

% plot consumption data
f = figure();
startDate = datenum(strcat(start_date, ' 00:00:00'));
endDate = datenum(strcat(end_date, ' 23:59:00'));
timeTics = linspace(startDate,endDate,86400/granularity);
plot(timeTics, consumptionArray);
datetickzoom('x', 'HH:MM');
ylabel('Power [W]');
xlabel('Time of day');
%legend('Household 1', 'Household 2', 'Household 4', 'Household 5', 'Household 6');
grid on;
%title(sprintf('Power Consumption of %s', appliance_name));
axis tight;
