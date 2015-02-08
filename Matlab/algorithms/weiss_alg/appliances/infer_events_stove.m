function [ result ] = infer_events_stove(result, events, times, threshold)

    appliance_name = 'Stove';
    phases = length(events);
    % check events that could be created by the stove of phase 1
    could_be_stove = abs(events{1}(:,1)) > threshold;
    times_could_be_stove = times{1}(could_be_stove);
    events_could_be_stove = events{1}(could_be_stove,1);
    for phase = 2:phases
        % check events that could be created by the stove of phase
        % "phase"
        could_be_stove = abs(events{phase}(:,1)) > threshold;
        times_phase = times{phase}(could_be_stove);
        % for each possible event on phase check if time lies within event on
        % old phase
        tmp = arrayfun(@(t) any(times_phase > t-5 & times_phase < t+5), times_could_be_stove);
        times_could_be_stove = times_could_be_stove(tmp);
        events_could_be_stove = events_could_be_stove(tmp);
    end

    result.appliance_names = {appliance_name};

    % events inferred from algorithm
    % col1: event time
    % col2: appliance id
    % col3: delta
    num_events = length(times_could_be_stove);
    result.events = [times_could_be_stove, ones(num_events,1), events_could_be_stove];
end

