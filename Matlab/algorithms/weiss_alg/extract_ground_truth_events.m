function [ground_truth_events] = extract_ground_truth_events(appliance_consumption, setup)
  
    % detect events in plug data

    p_edgeThreshold = setup.p_edgeThreshold;
    p_filtering = setup.p_filtering;
    p_filtLength = setup.p_filtLength;
    ground_truth_events = [];
    		
    function_handle = str2func(p_filtering);
    appliance_consumption_filtered = function_handle(appliance_consumption, p_filtLength);
    diff_consumption = diff(appliance_consumption_filtered);
    edges = abs(diff_consumption) > p_edgeThreshold;
    events_start_time = find(diff(edges) == 1) + 1;
    events_end_time = find(diff(edges) == -1) + 1; 

    % skip appliance if the number of events is too low
    if length(events_start_time) < 2 || length(events_end_time) < 2
        return;
    end

    % make sure that the events' end and start time are correct
    if events_end_time(1) < events_start_time(1)
        events_end_time = events_end_time(2:end);
    end
    if events_end_time(end) < events_start_time(end)
        events_start_time = events_start_time(1:end-1);
    end 

    % only select significant events
    idx_significant_events = find(events_start_time(2:end) - events_end_time(1:end-1) > 2);
    events_start_time = events_start_time([1, 1+idx_significant_events]);
    events_end_time = events_end_time([idx_significant_events, end]);

    % compute change in power caused by events
    power_change = appliance_consumption_filtered(1, events_end_time) - appliance_consumption_filtered(1, events_start_time);

    % ignore events that last too long ( > 60 seconds)
    idx_valid_events = events_end_time - events_start_time < 60;

    % store the ground truth (events in plug data)
    ground_truth_events = [ground_truth_events; events_start_time(idx_valid_events)', events_end_time(idx_valid_events)', power_change(idx_valid_events)', repmat(1, length(events_start_time(idx_valid_events)), 1)];

end