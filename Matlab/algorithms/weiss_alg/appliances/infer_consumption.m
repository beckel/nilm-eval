function [ consumption ] = infer_consumption(result, evaluation_and_training_days, usage_duration, appliance, setup)

    %% infer consumption from average consumption of corresponding appliance
    num_measurements = size(evaluation_and_training_days{1},1) * 86400 / setup.granularity;
    consumption = zeros(1, num_measurements);

    %% Fridge, Freezer, TV, Stereo
    if strcmp(appliance, 'Fridge') == 1 ...
            || strcmp(appliance, 'Freezer') == 1 ...
            || strcmp(appliance, 'TV') == 1 ...
            || strcmp(appliance, 'Stereo') == 1
        
        warning('off');
        training_days = evaluation_and_training_days{2};
        [avg_runtime, plug_events] = get_average_runtime_from_plug_data(appliance, training_days, setup);
        average_power = get_average_power_from_plug_data(appliance, training_days, setup, plug_events);
        %% HERE

        times = result.events(:,1);
        on_events = result.events(:,3) > 0;
        times_on_events = times(on_events);
        times_off_events = times(~on_events);   
        events_to_skip = [];
        for i = 1:length(times)
            if any(events_to_skip == i)
                continue;
            end
            % is on event
            % on event: check if off_event is within runtime
            % yes: on_event:off_event, increase by off_event
            % no: on_event:on_event+runtime, increase by runtime [ check boundaries ]
            if on_events(i) == 1
                switch_on = times(i);
                potential_off_events = times_off_events > switch_on & times_off_events < switch_on + avg_runtime;
                if any(potential_off_events)
                    off_idx = min(find(potential_off_events));
                    switch_off = times_off_events(off_idx);
                    consumption(switch_on:switch_off) = average_power;
                    % skip off event
                    idx_off_event = find(times == switch_off);
                    events_to_skip = [events_to_skip, i:idx_off_event];
                else
                    if switch_on + avg_runtime <= num_measurements
                        consumption(switch_on:switch_on+avg_runtime) = average_power;
                    else
                        consumption(switch_on:end) = average_power;
                    end
                end
            % off event: check if on_event is within runtime
            % yes: on_event:off_event;
            % [ not possible, this case is handled above ]
            % no: off_event-runtime:off_event [ check boundaries ]
            else
                switch_off = times(i);
                if switch_off - avg_runtime >= 1
                    consumption(switch_off-avg_runtime:switch_off) = average_power;
                else
                    consumption(1:switch_off) = average_power;
                end
            end
        end
        warning('on');
        
        
        
        
        
        
        
    elseif strcmp(appliance, 'Dishwasher') == 1
        for times = result.usage_times_start
            average_power = 1000; %1 kWh
            consumption(times:times+usage_duration-1) = average_power / usage_duration * 3600;
        end
        
    elseif strcmp(appliance, 'Water kettle') == 1
        average_power = 1800;
        times = result.events(:,1)
        on_events = result.events(:,3) > 0
        times_on_events = times(on_events);
        times_off_events = times(~on_events);

        for i = 1:length(times_on_events)
           switch_on = times_on_events(i);
           potential_off_events = times_off_events > switch_on & times_off_events < switch_on + usage_duration;
           if any(potential_off_events)
               switch_off = times_off_events(max(find(potential_off_events)));
               consumption(switch_on:switch_off) = average_power;
           end
        end

    else
        error('Determining consumption for appliance %s not implemented yet');
    end
end