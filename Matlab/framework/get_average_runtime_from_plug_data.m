function [avg_runtime, plug_events] = get_average_runtime_from_plug_data(appliance_name, training_days, setup)

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

    if strcmp(appliance_name, 'TV') == 1 ...
            || strcmp(appliance_name, 'Stereo') == 1 ...
            || strcmp(appliance_name, 'Fridge') == 1 ...
            || strcmp(appliance_name, 'Freezer') == 1

        on_events = [];
        off_events = [];
        cons = appliance_consumption_training;
        for i = 1:length(cons)-1
            % on events
            if cons(i) < 20 && cons(i+1) >= 20
                on_events = [on_events; i, i+1, 1, 1];
            elseif cons(i) >= 20 && cons(i+1) < 20
                if length(on_events) == 0
                    continue;
                end
                off_events = [off_events; i, i+1, -1, 1];
            end
        end
        
        if length(off_events) > length(on_events)
            off_events(end) = [];
        end
        
        avg_runtime = mean(off_events(:,1) - on_events(:,1));
        plug_events = {off_events, on_events};
        
    else
        error('Not implemented for appliance %s', appliance_name);
    end
end