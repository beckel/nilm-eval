%% Average consumption per run
function [ avg_cons ] = get_average_power_from_plug_data(appliance, training_days, setup, plug_events)

    appliance_id = getApplianceID(appliance);
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
    
    if strcmp(appliance, 'TV') == 1 ...
            || strcmp(appliance, 'Stereo') == 1

        avg_cons = setup.usage_consumption; % could be inferred from plug data as well
        
    elseif strcmp(appliance, 'Fridge') == 1 ...
            || strcmp(appliance, 'Freezer') == 1
        off_events = plug_events{1};
        on_events = plug_events{2};
        avg_cons = sum(appliance_consumption_training) / sum(off_events(:,1) - on_events(:,1));
        
    end
end

    