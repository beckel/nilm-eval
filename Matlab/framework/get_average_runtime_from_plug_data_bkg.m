function [avg_runtime] = get_average_runtime_from_plug_data(appliance_name, training_days, setup)

    appliance_id = getApplianceID(appliance_name);
    global caching;
    if caching == 1
        if exist('cache_plugs_training.mat') == 2
            load('cache_plugs_training');
        else
            appliance_consumption_training = read_plug_data(setup.dataset, setup.household, appliance_id, training_days, setup.granularity);
            save('cache_plugs_training', 'appliance_consumption_training');
        end
    else
        appliance_consumption_training = read_plug_data(setup.dataset, setup.household, appliance_id, training_days, setup.granularity);
    end
    
    if strcmp(appliance_name, 'TV') == 1
        ground_truth_events = extract_ground_truth_events(appliance_consumption_training, setup);
    elseif strcmp(appliance_name, 'Stereo') == 1
        events = [];
        cons = appliance_consumption_training;
        for i = 1:length(cons)-1
            if cons(i) < 20 && cons(i+1) >= 20
                events = [events; i, i+1, 1, 1];
            elseif cons(i) >= 20 && cons(i+1) < 20
                events = [events; i, i+1, -1, 1];
            end
        end
        ground_truth_events = events;
        % avg_runtime = setup.usage_duration;
    else
        error('Not implemented for appliance %s', appliance_name);
    end
   
    % check boundaries
    idx_start = 1; 
    if ground_truth_events(1,3 < 0)
        idx_start = 2;
    end

    idx_end = size(ground_truth_events,1);
    if (idx_end - idx_start) < 2
        avg_runtime = 0;
        return;
    end
    if ground_truth_events(idx_end,3) > 0
        idx_end = idx_end-1;
    end

    idx_start_events = idx_start : 2 : idx_end;
    idx_stop_events = idx_start+1 : 2 : idx_end;

    if length(idx_start_events) ~= length(idx_stop_events)
        error('Something wrong with start/stop events');
    end

    start_events = ground_truth_events(idx_start_events,:);
    stop_events = ground_truth_events(idx_stop_events,:);

    sum_runtime = 0;
    for i = 1:length(start_events)
        sum_runtime = sum_runtime + stop_events(i,2) - start_events(i,1);
    end
    avg_runtime = sum_runtime / length(start_events);

end