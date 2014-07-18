% parameters
interval = 60;
appliance_name = 'fridge';
households = 1:6;
maxNumOfDays = 20;
dates = zeros(maxNumOfDays,6);
consumptionArray = zeros(maxNumOfDays*(24*60*60)/interval,6);
missingValuesThresholdPlugs = 0;

% obtain consumption data
appliance_id =  getApplianceID(appliance_name);
houses = intersect(findHouseholds(appliance_id), households);
numOfDaysPerHousehold = zeros(length(houses), 1);
for i = houses
dates = getDates(i, maxNumOfDays, appliance_id, missingValuesThresholdPlugs);
numOfDaysPerHousehold(i) = length(dates);
consumption = read_plug_data(i, appliance_id, dates, interval );
consumptionArray(1:length(consumption),i) = consumption;
end

% plot consumption data
f = figure();
timeTics = 1:maxNumOfDays*86400/interval;
plot( timeTics, consumptionArray);
ylabel('Power [W]');
xlabel('Time of day');
legend('Household1', 'Household2', 'Household3', 'Household4', 'Household5', 'Household6');
grid on;
title(sprintf('Power Consumption of %s', appliance_name));
axis tight;

% statistics
meanCycleConsumptionPerHousehold = zeros(length(houses), 1);
medianCycleConsumptionPerHousehold = zeros(length(houses), 1);
stdPowerStepsPositive = zeros(length(houses), 1);
meanPowerStepsPositive = zeros(length(houses), 1);
medianPowerStepsPositive = zeros(length(houses), 1);
numOnEvents = zeros(length(houses), 1);
onDurationArray = zeros(length(houses), 2);
offDurationArray = zeros(length(houses), 2);
for i = houses
   consumption = consumptionArray(:, i); 
   threshold_consumption = consumption > 15;
   diff_consumption = diff(threshold_consumption);
   startIndex = find(diff_consumption > 0);
   endIndex = find(diff_consumption < 0);
   if (length(endIndex) <1 || length(startIndex) < 1) 
      continue; 
   end
   if endIndex(1) < startIndex(1)
       endIndex = endIndex(2:end);
   end
   if startIndex(end) > endIndex(end)
       startIndex = startIndex(1:end-1);
   end
   
   %power on intervals
   onDuration = endIndex - startIndex + 1;
   numOnEvents(i) = length(onDuration);
   onDurationArray(i, 1) = median(onDuration);
   onDurationArray(i, 2) = mean(onDuration);
   %figure();
   %hist(onDuration, 1:60);
   %title(sprintf('Duration of "power on intervals" of the %s in household %d  (median: %d, mean: %.2f)', appliance_name, ...
   %    i, onDurationArray(i, 1), onDurationArray(i, 2)));
   %ylabel('Number');
   %xlabel('Duration in minutes');
   
   % power off intervals
   offDuration = startIndex(2:end) - endIndex(1:end-1);
   offDurationArray(i, 1) = median(offDuration);
   offDurationArray(i, 2) = mean(offDuration);
   %figure();
   %hist(offDuration, 100);
   %title(sprintf('Duration of "power off intervals" of the %s in household %d  (median: %d, mean: %.2f)', appliance_name, ...
   %    i, offDurationArray(i, 1), offDurationArray(i, 2)));
   %ylabel('Number');
   %xlabel('Duration in minutes');
   
   consumptionDiff = diff(consumption);
   consumptionPerCycle = zeros(length(startIndex), 1);
   powerStepsPositive = zeros(length(startIndex), 1);
   for cycle = 1:length(startIndex)
        consumptionPerCycle(cycle) = mean(consumptionArray(startIndex(cycle)+1:endIndex(cycle),i)); 
        powerStepsPositive(cycle) = max(consumptionDiff(startIndex(cycle)), consumptionDiff(startIndex(cycle)+1));
   end
   meanCycleConsumptionPerHousehold(i) = mean(consumptionPerCycle);
   medianCycleConsumptionPerHousehold(i) = median(consumptionPerCycle);
   meanPowerStepsPositive(i) = mean(powerStepsPositive);
   medianPowerStepsPositive(i) = median(powerStepsPositive);
   stdPowerStepsPositive(i) = std(powerStepsPositive);
   %figure();
   %hist(powerStepsPositive, 100);
end

% output
medianOn = onDurationArray(:, 1);
meanOn = onDurationArray(:, 2);
medianOff = offDurationArray(:, 1);
meanOff = offDurationArray(:, 2);
file_name = strcat('results/thun_analysis/plot_all_households/',appliance_name,'_interval_',int2str(interval), '.txt');
fid = fopen(file_name, 'w');
fprintf(fid, '%6s %10s %10s %10s %10s %8s\n','house', 'medianOn', 'meanOn', 'medianOff', 'meanOff', 'numDays'); 
for i = houses
    fprintf(fid, '%6d %10.0f %10.2f %10.0f %10.2f %8d\n', i, medianOn(i), meanOn(i), medianOff(i), ...
        meanOff(i), numOfDaysPerHousehold(i));  
end
fprintf(fid, '\n\n %16s %16s %16s\n', 'cyclesPerDay', 'meanCycleCons', 'medianCycleCons');
for i = houses
    fprintf(fid, '%16.0f %16.0f %16.0f\n', numOnEvents(i)/numOfDaysPerHousehold(i), meanCycleConsumptionPerHousehold(i), ...
        medianCycleConsumptionPerHousehold(i));
end
fprintf(fid, '\n\n %16s %16s %16s\n', 'meanStepsPos', 'medianStepsPos', 'stdPowerSteps');
for i = houses
    fprintf(fid, '%16.0f %16.2f  %16.0f\n', meanPowerStepsPositive(i), ...
        medianPowerStepsPositive(i), stdPowerStepsPositive(i));
end
fclose(fid);
