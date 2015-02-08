function [ usage, usage_times_start ] = infer_usage(appliance_name, events, times, num_measurements, usage_duration)

    if strcmp(appliance_name, 'Dishwasher') ~= 1 ...
        && strcmp(appliance_name, 'Stove') ~= 1 ...
        && strcmp(appliance_name, 'Water kettle') ~= 1 ...
        && strcmp(appliance_name, 'TV') ~= 1 ...
        && strcmp(appliance_name, 'Stereo') ~= 1
        && strcmp(appliance_name, 'Fridge') ~= 1
        error('Not implemented for appliance %s\n', appliance_name);
        return;
    end

    %% How often was the appliance used today?
    num_days = num_measurements/86400;
    usage = zeros(1, num_days);
    usage_times_start = [];
    for d = 1:num_days
        idx_start = (d-1) * 86400 + 1;
        idx_stop = d * 86400;
        on_events = events > 0;
        times_of_on_events = times(on_events);
        times_during_day = times_of_on_events(times_of_on_events > idx_start & times_of_on_events < idx_stop);
        while times_during_day > 0
            usage(d) = usage(d)+1;
            time_of_event = times_during_day(1);
            usage_times_start(end+1) = time_of_event;
            time_of_event = time_of_event + usage_duration;
            idc = find(times_during_day < time_of_event);
            times_during_day(idc) = [];
        end
    end
end

