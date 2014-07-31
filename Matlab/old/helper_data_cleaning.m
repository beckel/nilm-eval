% Define parameters
household = 2;
dates = ['2012-06-20'];
interval = 1;
plug = '03';

% Read power data from file(s)
total_power = read_smartmeter_data( household, dates, interval , 'powerallphases');
powerl1 = read_smartmeter_data( household, dates, interval , 'powerl1');
powerl2 = read_smartmeter_data( household, dates, interval , 'powerl2');
consumption_cooker = read_plug_data(household, 3, dates, interval);

consumption1 = read_plug_data( household, 1, dates, interval);
consumption2 = read_plug_data( household, 2, dates, interval);
consumption4 = read_plug_data( household, 4, dates, interval);
consumption5 = read_plug_data( household, 5, dates, interval);
consumption6 = read_plug_data( household, 6, dates, interval);
consumption7 = read_plug_data( household, 11, dates, interval);
consumption8 = read_plug_data( household, 12, dates, interval);
consumption9 = read_plug_data( household, 13, dates, interval);
total_power = total_power - consumption1 - consumption2 - consumption_cooker - consumption4 - consumption5 ...
    - consumption6 - consumption7 -consumption8 -consumption9;

power_diff = [0, diff(total_power)];
power_diff2 = [0, diff(powerl2)];

a = find(power_diff > 400 & power_diff2 > 200);
b = find(power_diff < -400 & power_diff2 < -200);

% Create new figure
f = figure();
timeTics = 1:86400/interval;
plot(timeTics, total_power, 'b', timeTics, consumption_cooker, 'r', timeTics, powerl1, 'm', timeTics, powerl2, 'k');

datetick('x', 'HH:MM');
ylabel('Power [W]');
xlabel('Time of day');
legend('Total Power - Plugs', 'Herdabzug', 'Phase 1', 'Phase 2');
grid on;
%title({'Total Power Consumption vs Plug Power Consumption', sprintf('%s to %s (Household: %s, Plug: %s) ', start_date, end_date, household, plug)});

axis tight;


