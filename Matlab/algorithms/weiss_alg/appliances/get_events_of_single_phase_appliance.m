function [events, times] = get_events_of_single_phase_appliance(phase, input_params)
  
    events = [];
    times = [];

    dataset = input_params.dataset;
    household = input_params.household;
    evaluation_days = input_params.evaluation_days;
    granularity = input_params.granularity;
    filteringMethod = input_params.filtering_method;
    filtLength = input_params.filtLength;
    edgeThreshold = input_params.filtLength;
    plevelMinLength = input_params.plevelMinLength;
    eventPowerStepThreshold = input_params.eventPowerStepThreshold;
    maxEventDuration = input_params.maxEventDuration;
    
    % get real, apparent and reactive (distortive and translative
    % component) power
    global caching;
    if caching == 1
        if exist('cache_power.mat') == 2
            load('cache_power');
        else
            power = getPower(dataset, household, evaluation_days, granularity, phase);
            save('cache_power', 'power');
        end
    else
        power = getPower(dataset, household, evaluation_days, granularity, phase);
    end
    % apply filter to normalized apparent power and get edges 
    function_handle = str2func(filteringMethod);
    normalized_apparent_power_filtered = function_handle(power.normalized_apparent, filtLength);
    [rows, cols] = find(abs(diff(normalized_apparent_power_filtered)) > edgeThreshold);
    edges = sparse(rows, cols, ones(length(rows),1), 1, size(normalized_apparent_power_filtered,2)-1);

    % get power levels (period between two edges with similar power values)
    [plevel] = getPowerLevelsStartAndEndTimes(edges, plevelMinLength);       
    if isempty(plevel.startidx)
        return;
    end

    % get characteristics of power levels
    plevel = getPowerLevelProperties(plevel, power, plevelMinLength);

    % generate event vectors by taking the diffference between two consecutive power levels
    event_vecs = zeros(length(plevel.startidx)-1, 4);
    eventIsValid = zeros(length(plevel.startidx), 1);
    numOfEvents = 0;
    for i = 1:length(plevel.startidx)-1
           if abs(plevel.mean.end(i,1) - plevel.mean.start(i+1,1)) > eventPowerStepThreshold && plevel.startidx(i+1) - plevel.endidx(i) < maxEventDuration
                eventIsValid(i) = 1;
                numOfEvents = numOfEvents + 1;
                event_vecs(numOfEvents, 1:3) = plevel.mean.start(i+1, :) - plevel.mean.end(i, :);
                max_std_true_power = max(plevel.std(i,1), plevel.std(i+1,1));
                max_std_reactive_power = max(plevel.std(i,2), plevel.std(i+1,2));
                oscillationTerm = norm([max_std_true_power, max_std_reactive_power]);
                event_vecs(numOfEvents, 4) = oscillationTerm;
           end
    end
    event_vecs = event_vecs(1:numOfEvents, :);
    timeOfEvents = plevel.endidx(eventIsValid==1)'; 

    events = event_vecs;
    times = timeOfEvents;
end