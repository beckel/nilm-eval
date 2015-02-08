function [ plug_data_available ] = is_plug_data_available(appliance_name, setup, evaluation_days)
    dataset = setup.dataset;
    household = setup.household;
    granularity = setup.granularity;
            
    % detect events in plug data
    global caching;
    if caching == 1
        if exist('cache_plugs.mat') == 2
            load('cache_plugs');
        else
            appliance_consumption = read_plug_data(dataset, household, getApplianceID(appliance_name), evaluation_days, granularity);
            save('cache_plugs', 'appliance_consumption');
        end
    else
        appliance_consumption = read_plug_data(dataset, household, getApplianceID(appliance_name), evaluation_days, granularity);
    end
    
    num_days = size(evaluation_days,1);
    plug_data_available = zeros(1,num_days);
    for d = 1:num_days
        idx_start = 86400 * (d-1) + 1;
        idx_stop = 86400 * d;
        plug_data_available(d) = sum(appliance_consumption(idx_start:idx_stop) ~= -1) > 0.8 * 86400;
    end
end