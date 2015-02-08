% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [summary] = calculate_performance_consumption(summary, iteration, setup, evaluation_days, result)

    % compute performance regarding the inferred consumption of appliances

    % load parameters
    appliance_names = result.appliance_names;
    inferred_consumption_matrix = result.consumption;
    household = setup.household;
    granularity = setup.granularity;
    dataset = setup.dataset;

    % initialize performance metrics
    rms = zeros(length(appliance_names), 1);
    deviationPct = zeros(length(appliance_names), 1);
    npe = zeros(length(appliance_names), 1);
    precision = zeros(length(appliance_names), 1);
    recall = zeros(length(appliance_names), 1);
    f_score = zeros(length(appliance_names), 1);
    tpr = zeros(length(appliance_names), 1);
    fpr = zeros(length(appliance_names), 1);
    
    % load smart meter data
    global caching;
    if caching == 1
        if exist('cache_total.mat') == 2
            load('cache_total');
        else
            total_consumption = read_smartmeter_data(dataset, num2str(household, '%02d'), evaluation_days, granularity, 'powerallphases');
            save('cache_total', 'total_consumption');
        end
    else
        total_consumption = read_smartmeter_data(dataset, num2str(household, '%02d'), evaluation_days, granularity, 'powerallphases');
    end

    % compute performance for each appliance
    for i  = 1:length(appliance_names)
        % load ground truth data (plug-level data)
        appliance_name = cell2mat(appliance_names(i));
        appliance = getApplianceID(appliance_name);
        if caching == 1
            if exist('cache_plugs.mat') == 2
                load('cache_plugs');
            else
                appliance_consumption = read_plug_data(dataset, household, appliance, evaluation_days, granularity);
                save('cache_plugs', 'appliance_consumption');
            end
        else
            appliance_consumption = read_plug_data(dataset, household, appliance, evaluation_days, granularity);
        end
        
%         actual_consumption = actual_consumption(1:100);
%         total_consumption = total_consumption(1:100);
        % load the inferred consumption data
        inferred_consumption = inferred_consumption_matrix(i, :);

        % calculate root mean square error (rms), deviation in percentage (deviationPct) and
        % normalised error in assigned power (npe)
        error = abs(appliance_consumption - inferred_consumption);
        index_data_exists = appliance_consumption ~= -1 & total_consumption ~= -1;
        rms(i,1) = sqrt(mean(error(index_data_exists).^2));
        deviationAbs = sum(inferred_consumption(index_data_exists)) - sum(appliance_consumption(index_data_exists));
        deviationPct(i,1) = (abs(deviationAbs)) / sum(appliance_consumption(index_data_exists));
        npe(i,1) = sum(error(index_data_exists))/sum(appliance_consumption(index_data_exists));

        % calculate f_score, recall, precision, true positive rate (tpr), false
        % positive rate (fpr)
        idx_existing = appliance_consumption ~= -1 & total_consumption ~= -1;
        threshold = get_evaluation_threshold(appliance, household);
        idx_actual_on = appliance_consumption > threshold;
        idx_inferred_on = inferred_consumption > threshold;
        tp = nnz(idx_actual_on & idx_inferred_on & idx_existing);
        fp = nnz(~idx_actual_on & idx_inferred_on & idx_existing);
        tn = nnz(~idx_actual_on & ~idx_inferred_on & idx_existing);
        fn = nnz(idx_actual_on & ~idx_inferred_on & idx_existing);
        tpr_value = tp / (tp + fn);
        fpr_value = fp / (fp + tn);
        precision_value = tp/(tp + fp);
        recall_value = tp/(tp + fn);
        f_score(i,1) = 2*precision_value*recall_value/(precision_value + recall_value);
        precision(i,1) = precision_value;
        recall(i,1) = recall_value;
        tpr(i,1) = tpr_value;
        fpr(i,1) = fpr_value;
    end
    
    % store results
    summary.consumption.rms(:,iteration) = rms;
    summary.consumption.deviationPct(:,iteration) = deviationPct;
    summary.consumption.precision(:,iteration) = precision;
    summary.consumption.recall(:,iteration) = recall;
    summary.consumption.fscore(:,iteration) = f_score;
    summary.consumption.tpr(:,iteration) = tpr;
    summary.consumption.fpr(:,iteration) = fpr;
    summary.consumption.npe(:,iteration) = npe;
    
    summary.appliance_names = result.appliance_names;
end

