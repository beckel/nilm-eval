% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [] = nilm_eval(setup_file)
    
    startup;

    % load setup file and get name of algorithm, configuration and
    % experiment
    if ~exist('setup_file', 'var')
        error('setup file is missing')
    end
    setup = ReadYaml(setup_file);
    algorithm = setup.algorithm;
    configuration = setup.configuration;
    experiment = setup.experiment;
    setup_name = setup.setup_name;
    
    fprintf('running %s algorithm with %s configuration and % s setup file ... \n', algorithm, configuration, setup_name)

    % load parameters of algorithm/configuration
    dataset = setup.dataset;
    household = setup.household; 
    evalDays_type = setup.evalDays;
    numOfResults = setup.numOfResults;
    trainingDays = setup.trainingDays;

    % get evaluation days
    path_to_evalDays = strcat(pwd, '/input/autogen/evaluation_days/', dataset, '/', evalDays_type, '/', num2str(household, '%02d'), '.mat');
    load(path_to_evalDays); % evalDays

    % generate summary txt file
    path_to_results_summary = strcat('results/summary/', algorithm, '/', configuration, '/', experiment , '/', setup_name);
    if ~exist(path_to_results_summary, 'dir')
        mkdir(path_to_results_summary);
    end
    fid = fopen(strcat(path_to_results_summary, '/summary.txt'), 'w');
    
    % generate folder to store detailed results
    path_to_results_details = strcat('results/details/', algorithm, '/', configuration, '/', experiment , '/', setup_name);
    if ~exist(path_to_results_details, 'dir')
        mkdir(path_to_results_details);
    end

    summary = struct;
    for i = 1:numOfResults
        % infer consumption/events
        fprintf(fid,'result %d:\n\n', i);
        
        % set training and test days
        if trainingDays == 0
            evaluation_and_training_days{1} = evalDays;
            evaluation_and_training_days{2} = [];    
        else
            trainingRange = ((i-1)*trainingDays)+1 : i*trainingDays;
            evalRange = setdiff(1:size(evalDays,1), trainingRange);
            evaluation_and_training_days{1} = evalDays(evalRange, :);
            
            fprintf('size of evalDays: %d\n', size(evalRange));
            fprintf('size of trainingRange: %d\n', size(trainingRange));
            evaluation_and_training_days{2} = evalDays(trainingRange, :); 
        end
        
        % run algorithm with setup file
        function_handle = str2func(algorithm);
        result = function_handle(evaluation_and_training_days, setup, fid);

        % get rms, fscore, precision, recall, deviationPct and ... of inferred
        % consumption
        if isfield(result, 'consumption')
            [summary] = calculate_performance_consumption(summary, i, setup, evaluation_and_training_days{1}, result);
        end    
        % get fscore, precision, recall and ... of inferred events
        if isfield(result, 'events')
            [summary] = calculate_performance_events(summary, i, setup, evaluation_and_training_days{1}, result);
        end
        if isfield(result, 'usage')
            [summary] = calculate_performance_usage(summary, i, setup, evaluation_and_training_days{1}, result);
        end

        % add training and evaluation days as well as setup file
        result.evaluation_and_training_days = evaluation_and_training_days;
        result.setup = setup;
        result.setup_file = setup_file;
        
        % save result
        if ~exist(path_to_results_details, 'dir')
            mkdir(path_to_results_details);
        end
        result_file = strcat(path_to_results_details, '/result', num2str(i), '.mat');
        save(result_file, 'result');   
    end

    % write results (fscore, rms, etc.) to summary.txt file
    if isfield(result, 'consumption')
        fprintf(fid, 'Consumption:\n');
        for applianceIDX = 1:size(summary.consumption.fscore,1)
           fprintf(fid, '%s: \n', cell2mat(summary.appliance_names(applianceIDX)));
           fprintf(fid, '%12s %10s %12s %10s %10s %10s %15s %10s %10s\n' , 'ResultNr', 'Fscore', 'Precision', 'Recall', 'TPR', 'FPR', 'DeviationPct', 'RMS', 'NPE'); 
           for resultIDX = 1:size(summary.consumption.fscore,2)
              fprintf(fid, '%12d %10.4f %12.4f %10.4f %10.4f %10.4f %15.4f %10.4f %10.4f\n', resultIDX, summary.consumption.fscore(applianceIDX,resultIDX), ...
                  summary.consumption.precision(applianceIDX,resultIDX), summary.consumption.recall(applianceIDX,resultIDX), ...
                  summary.consumption.tpr(applianceIDX,resultIDX), summary.consumption.fpr(applianceIDX,resultIDX), ...
                  summary.consumption.deviationPct(applianceIDX,resultIDX), summary.consumption.rms(applianceIDX,resultIDX), ...
                  summary.consumption.npe(applianceIDX,resultIDX));
           end
           fprintf(fid, '\n');
        end
    end
    if isfield(result, 'events')
        fprintf(fid, 'Events:\n');
        for eventIDX = 1:size(summary.events.fscore,1)
           fprintf(fid, '%s: \n', summary.appliance_names{eventIDX});
           fprintf(fid, '%10s %10s %10s %10s %16s %10s\n' , 'ResultNr', 'Fscore', 'Precision', 'Recall', 'Appliance', 'FP_Fraction'); 
           for resultIDX = 1:size(summary.events.fscore,2)
               [max_fraction_value, max_fraction_ID] = max(summary.events.fraction(:,eventIDX, resultIDX));
              fprintf(fid, '%10d %10.4f %10.4f %10.4f %16s %10.4f\n', resultIDX, summary.events.fscore(eventIDX,resultIDX), ...
                  summary.events.precision(eventIDX,resultIDX), summary.events.recall(eventIDX,resultIDX), ...
                  cell2mat(summary.appliance_names(max_fraction_ID)), max_fraction_value);
           end
        end
    end
    
    if isfield(result, 'usage')
        fprintf(fid, 'Usage:\n');
        fprintf(fid, 'Appliance: %s\n\n', summary.usage.appliance_name);
        fprintf(fid, '\n\nInferred usage vs. actual usage: \n\n');
        for i = 1:length(summary.usage.inferred_usage)
            fprintf(fid, '%s: %d - %d\n', evaluation_and_training_days{1}(i,:), summary.usage.inferred_usage(i), summary.usage.ground_truth_usage(i));
        end
        fprintf(fid, '\n\n');
        
        fprintf(fid, 'Number of days: %d\n', summary.usage.num_days);
        fprintf(fid, 'F-Score: %f\n', summary.usage.fscore);
        fprintf(fid, 'Recall: %f\n', summary.usage.recall);
        fprintf(fid, 'Precision: %f\n', summary.usage.precision);
        fprintf(fid, 'True positives: %d\n', summary.usage.tp);
        fprintf(fid, 'False positives: %d\n', summary.usage.fp);
        fprintf(fid, 'False negatives: %d\n', summary.usage.fn);
        fprintf(fid, 'Ratio (overall): %f\n', summary.usage.overall_ratio);
        fprintf(fid, 'Days correctly estimated that appliance was running: %f\n', summary.usage.days_correct);
    end

    fclose(fid);

    % save experiment result
    summary_file = strcat(path_to_results_summary, '/summary.mat');
    save(summary_file, 'summary'); 
end