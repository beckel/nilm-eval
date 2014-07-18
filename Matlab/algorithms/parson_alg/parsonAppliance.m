% This file is part of the following project:
% Oliver Parson, Siddhartha Ghosh, Mark Weal, Alex Rogers.
% Non-intrusive Load Monitoring using Prior Models of General Appliance Types.
% In: 26th AAAI Conference on Artificial Intelligence. Toronto, Canada. 2012.
% Code available for download: https://sites.google.com/site/oliparson/phd-work/research-files/aaai-2012-code.zip?attredirects=0
% Copyright: Oliver Parson et al., University of Southhampton, 2012.

% Modified by Romano Cicchetti, ETH Zurich, in the context of the NILM-Eval project


function [result] = parsonAppliance(evaluation_and_training_days, setup, fid)

        %load parameters        
        dataset = setup.dataset;
        household = setup.household;
        granularity = setup.granularity;
        filtering = setup.filtering;
        if isfield(setup,'filtering2')
            filtering2 = setup.filtering2;
        else
            filtering2 = 'noFiltering';
        end
        filtWindowLength = setup.filtWindowLength;
        filtLRatio = setup.filtLRatio;
        phases = setup.phases;
        
        applianceName = setup.applianceName;
        state_means = [setup.meanOff, setup.meanOn] ;
        state_covs = [setup.varOff, setup.varOn];
        transition_matrix = [1-setup.transOn, setup.transOn;
                            setup.transOff, 1-setup.transOff];
        likelihoodThreshold = setup.likThresh;
        numOfWindows = setup.numOfWindows;
        windowLength = setup.windowLength;
        trainingType = setup.trainingType;

        
        windowLength = windowLength/granularity;

        % get training and test data
        evaluation_days = evaluation_and_training_days{1};
        training_days = evaluation_and_training_days{2};
        applianceID = getApplianceID(applianceName);
        if strcmpi(phases, 'indv')
            phase_of_appliance = getPhase(household, applianceID);
            read_smartmeter_option = strcat('powerl', num2str(phase_of_appliance));
            test_data = read_smartmeter_data(dataset, num2str(household, '%02d'), evaluation_days, granularity, read_smartmeter_option);
            training_data = read_smartmeter_data(dataset, num2str(household, '%02d'), training_days, granularity, read_smartmeter_option);
        elseif strcmpi(phases, 'all')
            test_data = read_smartmeter_data(dataset, num2str(household, '%02d'), evaluation_days, granularity, 'powerallphases');
            training_data = read_smartmeter_data(dataset, num2str(household, '%02d'), training_days, granularity, 'powerallphases');
        else
            error('wrong value for phases parameter');
        end
        plug_data  = read_plug_data(dataset, household, applianceID, training_days, granularity);
        
        % apply filtering method to consumption data 
        if ~strcmpi(filtering, 'noFiltering')
            function_handle = str2func(filtering);
            if strcmpi(filtering, 'totalVar')
                test_data = function_handle(test_data, filtLRatio);
                training_data = function_handle(training_data, filtLRatio);
                plug_data = function_handle(plug_data, filtLRatio);
            elseif strcmpi(filtering, 'edgeEnhance5')
                test_data = function_handle(test_data);
                training_data = function_handle(training_data);
                plug_data = function_handle(plug_data);
            else
                test_data = function_handle(test_data, filtWindowLength);
                plug_data = function_handle(plug_data, filtWindowLength);
            end
        end           
        if ~strcmpi(filtering2, 'noFiltering')
            function_handle = str2func(filtering2);
            if strcmpi(filtering2, 'totalVar')
                test_data = function_handle(test_data, filtLRatio);
                training_data = function_handle(training_data, filtLRatio);
                plug_data = function_handle(plug_data, filtLRatio);
            elseif strcmpi(filtering2, 'edgeEnhance5')
                test_data = function_handle(test_data);
                training_data = function_handle(training_data);
                plug_data = function_handle(plug_data);
            else
                test_data = function_handle(test_data, filtWindowLength);
                training_data = function_handle(training_data, filtWindowLength);
                plug_data = function_handle(plug_data, filtWindowLength);
            end
        end 

        % calculate diff model params
        init = ones(1, length(state_means)) / length(state_means);
        num_states = length(init);
        idx = repmat(1:num_states,num_states,1);
        emit_mean = state_means(idx) - state_means(idx');
        emit_cov = state_covs(idx) + state_covs(idx');

        % make difference hmm
        prior_dhmm_bnet = make_dhmm(init, ...
                          emit_mean, ...
                          emit_cov, ...
                          state_means, ...
                          state_covs, ...
                          transition_matrix);
   
        prior_hmm_bnet = make_hmm(init, ...
                         state_means, ...
                         state_covs, ...
                         transition_matrix);

        % data evidence
        diffs = [0 diff(test_data)];
        evidence = {};
        evidence(2,:) = num2cell(diffs);

        %create engine
        engine = smoother_engine(jtree_2TBN_inf_engine(prior_dhmm_bnet));

        %select windows of training data
        if strcmpi(trainingType, 'noTraining')
            
        elseif strcmpi(trainingType, 'aggregateTraining')
                [training_windows, ~] = find_training_ranges_generic(training_data, ...
                            windowLength, prior_dhmm_bnet, numOfWindows);
               
        elseif strcmpi(trainingType, 'plugTraining')
            plug_data_with_noise = awgn(plug_data, 25, 'measured');
            [training_windows, ~] = find_training_ranges_generic(plug_data_with_noise, ...
                            windowLength, prior_dhmm_bnet, numOfWindows);
        end

        %train models
        if strcmpi(trainingType, 'noTraining')
            trained_hmm_bnet = prior_hmm_bnet;
            trained_dhmm_bnet = prior_dhmm_bnet;
        elseif strcmpi(trainingType, 'aggregateTraining') || strcmpi(trainingType, 'plugTraining')
            [trained_dhmm_bnet, ~] = learn_params_generic(prior_dhmm_bnet, diff(training_windows'));
                emission3 = struct(trained_dhmm_bnet.CPD{4});
                dHMM_means = permute(emission3.mean, [2,3,1]);
                dHMM_covs = permute(emission3.cov, [3,4,1,2]);
            try
                [trained_hmm_bnet, ~] = learn_params_generic(prior_hmm_bnet, training_windows');
            catch err
                trained_hmm_bnet = prior_hmm_bnet;
            end
            trained_dhmm_bnet.CPD{1} = tabular_CPD(trained_dhmm_bnet, 1, 'CPT', ones(1, length(init)) / length(init));
            trained_dhmm_bnet.CPD{2} = trained_hmm_bnet.CPD{2};
            trained_dhmm_bnet.CPD{3} = prior_dhmm_bnet.CPD{3};
        end
        hmm_emissions = struct(trained_hmm_bnet.CPD{2});

        % infer power (viterbi)
        evidence(3,:) = num2cell(test_data);
        [mpe] = my_viterbi_diff(trained_dhmm_bnet, evidence, 1, likelihoodThreshold);       
        means = hmm_emissions.mean;
        result = struct;
        result.consumption = means(cell2mat(mpe(1,:)));
        result.appliance_names = {applianceName};
        
        % write to summary text file
        fprintf(fid, 'trained HMM means:\n');
        fprintf(fid, [repmat('%f\t', 1, size(hmm_emissions.mean(:),2)) '\n'], hmm_emissions.mean(:));
        fprintf(fid, '\ntrained HMM covs:\n');
        fprintf(fid, [repmat('%f\t', 1, size(hmm_emissions.cov(:),2)) '\n'], hmm_emissions.cov(:));
        if strcmpi(trainingType, 'aggregateTraining') || strcmpi(trainingType, 'plugTraining') 
            fprintf(fid, '\ntrained dHMM means:\n');
            fprintf(fid, [repmat('%f\t', 1, size(dHMM_means,2)) '\n'], dHMM_means');
            fprintf(fid, '\ntrained dHMM covs:\n');
            fprintf(fid, [repmat('%f\t', 1, size(dHMM_covs,2)) '\n'], dHMM_covs');
            fprintf(fid, '\n\n');
        else
            fprintf(fid, '\n');
        end
end


    




