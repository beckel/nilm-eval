% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [summary] = calculate_performance_events(summary, iteration, setup, evaluation_days, result)

    % compute performance regarding the inferred events

    % load parameter values
    inferred_events = result.events;
    inferred_event_names = result.event_names;
    household = setup.household;
    granularity = setup.granularity;
    dataset = setup.dataset;
    setup_name = setup.setup_name;
    p_edgeThreshold = setup.p_edgeThreshold;
    p_filtering = setup.p_filtering;
    p_filtLength = setup.p_filtLength;
    p_filtLRatio = setup.p_filtLRatio;
    
    appliances = findAppliances(household, dataset);

    % get ground truth form plug-level data
    ground_truth_events = [];
    eventID = 1;
    for appliance = appliances
        % detect events in plug data
        appliance_consumption = read_plug_data(dataset, household, appliance, evaluation_days, granularity);
        function_handle = str2func(p_filtering);
        appliance_consumption_filtered = function_handle(appliance_consumption, p_filtLength);
        diff_consumption = diff(appliance_consumption_filtered);
        edges = abs(diff_consumption) > p_edgeThreshold;
        events_start_time = find(diff(edges) == 1) + 1;
        events_end_time = find(diff(edges) == -1) + 1; 
        
        % skip appliance if the number of events is too low
        if length(events_start_time) < 2 || length(events_end_time) < 2
            continue;
        end
        
        % make sure that the events' end and start time are correct
        if events_end_time(1) < events_start_time(1)
            events_end_time = events_end_time(2:end);
        end
        if events_end_time(end) < events_start_time(end)
            events_start_time = events_start_time(1:end-1);
        end 
        
        % only slect significant events
        idx_siginificant_events = find(events_start_time(2:end) - events_end_time(1:end-1) > 5);
        events_start_time = events_start_time([1, 1+idx_siginificant_events]);
        events_end_time = events_end_time([idx_siginificant_events, end]);
        
        % compute change in power caused by events
        power_change = appliance_consumption_filtered(1, events_end_time) - appliance_consumption_filtered(1, events_start_time);
        
        % ignore events that last too long ( > 60 seconds)
        idx_valid_events = events_end_time - events_start_time < 60;

        % store the ground truth (events in plug data)
        ground_truth_events = [ground_truth_events; events_start_time(idx_valid_events)', events_end_time(idx_valid_events)', power_change(idx_valid_events)', repmat(eventID, length(events_start_time(idx_valid_events)), 1)];
        appliance_name = getApplianceNames([appliance]);
        ground_truth_event_names{eventID} = cell2mat(appliance_name(1));
        eventID = eventID + 1;
    end

    % initialize performance metrics
    appliance_names = getApplianceNames(appliances);
    events_fscore = zeros(length(appliance_names), 1);
    events_precision = zeros(length(appliance_names), 1);
    events_recall = zeros(length(appliance_names), 1);
    events_tp = zeros(length(appliance_names), 1);
    events_fp = zeros(length(appliance_names), 1);
    events_fn = zeros(length(appliance_names), 1);
    fraction = zeros(length(appliance_names),length(appliance_names));
    
    % compute performance metrics for each appliance
    for i = 1:length(appliance_names)
        appliance_name = cell2mat(appliance_names(i));
        ground_truth_eventID = find(ismember(ground_truth_event_names, appliance_name));
        inferred_eventID = find(ismember(inferred_event_names, appliance_name));
        
        % skip appliance if the ground truth is not known
        if isempty(inferred_eventID) || isempty(ground_truth_eventID)
            events_precision(i, 1) = NaN;
            events_recall(i, 1) = NaN;
            events_fscore(i, 1) = NaN;
            continue;
        end
        
        % store indexes of ground truth and inferred events
        idx_ground_truth_events = ground_truth_events(:,4) == ground_truth_eventID;
        idx_inferred_events = find(inferred_events(:,2) == inferred_eventID);
        
        % compute number of false positives, false negatives and true
        % positives
        ind_ground_truth_events = find(idx_ground_truth_events);
        vec = arrayfun(@(t) any(ground_truth_events(idx_ground_truth_events,1) - 10 < t & t < ground_truth_events(idx_ground_truth_events,2) + 10),...
            inferred_events(idx_inferred_events, 1));
        vec2 = arrayfun(@(id) any(ground_truth_events(id,1) - 10 < inferred_events(idx_inferred_events, 1) & ...
            inferred_events(idx_inferred_events, 1) < ground_truth_events(id,2) + 10), ind_ground_truth_events);
        applianceID = getApplianceID(appliance_name);
        appliance_consumption = read_plug_data(dataset, household, applianceID, evaluation_days, granularity);
        plug_data_exists = arrayfun(@(t) ~any(appliance_consumption(1, max(1,t-5):min(t+5,size(appliance_consumption,2))) == -1), inferred_events(idx_inferred_events, 1));
        tp = nnz(vec);
        fp = nnz(~vec & plug_data_exists);
        fn = nnz(~vec2);
        
        % compute f-score, precision and recall
        if tp + fp == 0
            precision = 0;
        else
            precision = tp / (tp + fp);
        end
        if nnz(idx_ground_truth_events) == 0
            recall = 0;
        else
            recall = nnz(vec2) / nnz(idx_ground_truth_events);
        end
        if precision + recall == 0
            fscore = 0;
        else
            fscore = 2* precision * recall /(precision + recall);
        end 
        
        % store computed performance metrics
        events_precision(i, 1) = precision;
        events_recall(i, 1) = recall;
        events_fscore(i, 1) = fscore;
        events_tp(i, 1) = tp;
        events_fp(i, 1) = fp;
        events_fn(i, 1) = fn;
        
        % learn to which appliances the events assigned to appliance i
        % belong
        idx_fp = idx_inferred_events(~vec & plug_data_exists);
        fp_events_time = inferred_events(idx_fp,1);
        for j = 1:length(appliance_names)
           if j == i, continue; end
           app_name = cell2mat(appliance_names(j));
           ground_truth_eventID = find(ismember(ground_truth_event_names, app_name));
           if isempty(ground_truth_eventID)
               fraction(j,i) = 0;
           else
                idx_ground_truth_events = ground_truth_events(:,4) == ground_truth_eventID;
                vec2 = arrayfun(@(t) any(ground_truth_events(idx_ground_truth_events,1) - 10 < t & t < ground_truth_events(idx_ground_truth_events,2) + 10), fp_events_time);
                fraction(j,i) = nnz(vec2)/nnz(plug_data_exists);
           end
        end
        
    end
    
    % store results
    summary.events.fscore(:, iteration) = events_fscore;
    summary.events.recall(:, iteration) = events_recall;
    summary.events.precision(:, iteration) = events_precision;
    summary.events.tp(:, iteration) = events_tp;
    summary.events.fp(:, iteration) = events_fp;
    summary.events.fn(:, iteration) = events_fn;
    summary.events.fraction = fraction;
    summary.event_names = getApplianceNames(appliances);
end

