   % This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Christian Beckel

function [summary] = calculate_performance_usage(summary, iteration, setup, evaluation_days, result)

    inferred_appliance_names = result.appliance_names;
    inferred_usage = result.usage;

    % compute performance regarding the inferred events
    for i = 1:length(inferred_appliance_names)
        appliance_name = inferred_appliance_names{i};
        
        if strcmp(appliance_name, 'Dishwasher') ~= 1 ...
            && strcmp(appliance_name, 'Stove') ~= 1 ...
            && strcmp(appliance_name, 'Water kettle') ~= 1 ...
            && strcmp(appliance_name, 'TV') ~= 1 ...
            && strcmp(appliance_name, 'Stereo') ~= 1
            error('Not implemented for appliance %s\n', appliance_name);
            continue;
        end

        % load plug data
        granularity = setup.granularity;
        household = setup.household;
        dataset = setup.dataset;
        appliance_id = getApplianceID(appliance_name);
        global caching;
        if caching == 1
            if exist('cache_plugs.mat') == 2
                load('cache_plugs');
            else
                appliance_consumption = read_plug_data(dataset, household, appliance_id, evaluation_days, granularity);
                save('cache_plugs', 'appliance_consumption');
            end
        else
            appliance_consumption = read_plug_data(dataset, household, appliance_id, evaluation_days, granularity);
        end

        % load parameter values
        ground_truth_events = extract_ground_truth_events(appliance_consumption, setup);
        num_measurements = size(evaluation_days,1) * 86400;
        ground_truth_usage = infer_usage(appliance_name, ground_truth_events(:,3), ground_truth_events(:,1), num_measurements, setup.usage_duration);

        ground_truth_available = is_plug_data_available(appliance_name, setup, evaluation_days);
        ground_truth_usage = ground_truth_usage(ground_truth_available == 1);
        inferred_usage = inferred_usage(i, ground_truth_available == 1);

        num_days = sum(ground_truth_available);
        overall_ratio = sum(inferred_usage) / sum(ground_truth_usage);
        days_correct = sum((inferred_usage > 0) == (ground_truth_usage > 0)) / num_days;
        tp = sum(min(inferred_usage, ground_truth_usage));
        tmp = inferred_usage - ground_truth_usage;
        fp = sum(tmp(tmp > 0));
        tmp = ground_truth_usage - inferred_usage;
        fn = sum(tmp(tmp > 0));

        % compute f-score, precision and recall
        if tp + fp == 0
            precision = 0;
        else
            precision = tp / (tp + fp);
        end
        if tp + fn == 0
            recall = 0;
        else
            recall = tp / (tp + fn);
        end
        if precision + recall == 0
            fscore = 0;
        else
            fscore = 2 * precision * recall / (precision + recall);
        end 

        summary.usage.fscore = fscore;
        summary.usage.recall = recall;
        summary.usage.precision = precision;
        summary.usage.tp = tp;
        summary.usage.fp = fp;
        summary.usage.fn = fn;
        summary.usage.appliance_name = appliance_name;
        summary.usage.num_days = num_days;
        summary.usage.overall_ratio = overall_ratio;
        summary.usage.days_correct = days_correct;
        summary.usage.ground_truth_usage = ground_truth_usage;
        summary.usage.inferred_usage = inferred_usage;
    end
end


