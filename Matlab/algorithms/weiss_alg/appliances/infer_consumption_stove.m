function [ consumption ] = infer_consumption_stove(events, times, num_measurements, usage_duration)

    %% Consumption
    % search on events
    % search off events that are not too far away
    % compute difference 
    consumption = zeros(1, num_measurements);

    on_events = events > 0;
    off_events = events < 0;
    for i = 1:length(on_events)
        % discard if it is an off event
        if on_events(i) == 0
            continue;
        end
        time_on_event = times(i);
        % check if an off event follows this on event
        off_event_times = times(off_events);
        off_event_consumption = events(off_events);
        off_event_matches = off_event_times > time_on_event & off_event_times < (time_on_event + usage_duration);
        if any(off_event_matches)
            idx_off_event = min(find(off_event_matches));
            time_off_event = off_event_times(idx_off_event);
            consumption(time_on_event:time_off_event) = 2 * mean(abs([events(i), off_event_consumption(idx_off_event)]));
        end
    end

end

