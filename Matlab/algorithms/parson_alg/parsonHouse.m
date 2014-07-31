% This file is part of the following project:
% Oliver Parson, Siddhartha Ghosh, Mark Weal, Alex Rogers.
% Non-intrusive Load Monitoring using Prior Models of General Appliance Types.
% In: 26th AAAI Conference on Artificial Intelligence. Toronto, Canada. 2012.
% Code available for download: https://sites.google.com/site/oliparson/phd-work/research-files/aaai-2012-code.zip?attredirects=0
% Copyright: Oliver Parson et al., University of Southhampton, 2012.

% Modified by Romano Cicchetti, ETH Zurich, in the context of the NILM-Eval project


function [result] = parsonHouse(evaluation_and_training_days, params_struct)

    %load appliance parameters        
    phases = params_struct.phases;
    filtering = params_struct.filtering;
    method = params_struct.method;
    house = params_struct.household;
    interval = params_struct.interval;
    dataset = params_struct.dataset;
    trainingType = params_struct.trainingType;
    evaluation_days = evaluation_and_training_days{1};
    training_days = evaluation_and_training_days{2};
    
    % get training data and total consumption data
    if strcmpi(phases, 'usePhases')
        total_consumption_matrix = zeros(3, (86400/interval)*size(evaluation_days,1));
        t_data_matrix = zeros(3, (86400/interval)*size(training_days,1));
        for phase = 1:3
            read_smartmeter_option = strcat('powerl', num2str(phase));
            total_consumption_matrix(phase,:) = read_smartmeter_data(num2str(house, '%02d'), evaluation_days, interval, read_smartmeter_option);
            t_data_matrix(phase,:) = read_smartmeter_data(num2str(house, '%02d'), training_days, interval, read_smartmeter_option);
        end
    elseif strcmpi(phases, 'doNotUsePhases')
        total_consumption_matrix(1,:) = read_smartmeter_data(num2str(house, '%02d'), evaluation_days, interval, 'powerallphases');
        t_data_matrix(1,:) = read_smartmeter_data(num2str(house, '%02d'), training_days, interval, 'powerallphases');
    else
        error('wrong value for phases parameter');
    end
    
    % apply filtering method to consumption data
    if ~strcmpi(filtering, 'noFiltering')
        function_handle = str2func(filtering);
        total_consumption_matrix = function_handle(total_consumption_matrix,5);
        t_data_matrix = function_handle(t_data_matrix,5);
    end
    
    appliances = findAppliances(house, dataset);
    result = struct;
    result.consumption = zeros(length(appliances), length(evaluation_days) * 86400/interval);
    resCounter = 1;
    for appliance = appliances
        % load appliance specific parameters
        appliance_params = params_struct.doNotChange;
        num_of_windows = appliance_params.numOfWindows{appliance};
        likelihood_threshold = appliance_params.likThres{appliance};
        window_length = appliance_params.windowLength{appliance};
        state_means = [params_struct.meanOffRatio, params_struct.meanOnRatio] .* appliance_params.state_means{appliance};
        state_covs = [params_struct.varOffRatio, params_struct.varOnRatio] .* appliance_params.state_covs{appliance};
        transition_matrix = appliance_params.transition_matrix{appliance};
        
        window_length = window_length/60;

        if strcmpi(phases, 'usePhases')
            phase_of_appliance = getPhase(house, appliance);
            total_consumption = total_consumption_matrix(phase_of_appliance, :);
            t_data = t_data_matrix(phase_of_appliance, :);
            if strcmpi(method, 'iterative')
                appliances_of_same_phase = getAppliancesOfPhase(dataset, house, phase_of_appliance);
                idx_of_appliance = find(appliance == appliances_of_same_phase);
                if idx_of_appliance > 1
                    total_consumption = total_consumption - sum(result.consumption(appliances_of_same_phase(1:idx_of_appliance-1), :),1);
                end
            end
        else
            total_consumption = total_consumption_matrix(1, :);
            t_data = t_data_matrix(1, :);
            if strcmpi(method, 'iterative')
                idx_of_appliance = find(appliance == appliances);
                if idx_of_appliance > 1
                    total_consumption = total_consumption - sum(result.consumption(1:idx_of_appliance-1, :));
                end
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

        % REDD evidence
        diffs = [0 diff(total_consumption)];
        evidence = {};
        evidence(2,:) = num2cell(diffs);

        %create engine
        engine = smoother_engine(jtree_2TBN_inf_engine(prior_dhmm_bnet));

        %select training data
        if strcmpi(trainingType, 'noTraining')

        elseif strcmpi(trainingType, 'aggregateTraining')
                [training_data, ~] = find_training_ranges_generic(t_data, ...
                            window_length, prior_dhmm_bnet, num_of_windows);

        elseif strcmpi(trainingType, 'plugTraining')
            plug_data  = read_plug_data(house, appliance, training_days, interval);
            plug_data_with_noise = awgn(plug_data, 24, 'measured');
            [training_data, ~] = find_training_ranges_generic(plug_data_with_noise, ...
                            window_length, prior_dhmm_bnet, num_of_windows);
        end

        %train models
        if strcmpi(trainingType, 'noTraining')
            trained_hmm_bnet = prior_hmm_bnet;
            trained_dhmm_bnet = prior_dhmm_bnet;
        elseif strcmpi(trainingType, 'aggregateTraining') || strcmpi(trainingType, 'plugTraining')
            [trained_dhmm_bnet, ~] = learn_params_generic(prior_dhmm_bnet, diff(training_data'));
            try
                [trained_hmm_bnet, ~] = learn_params_generic(prior_hmm_bnet, training_data');
            catch err
                trained_hmm_bnet = prior_hmm_bnet;
            end
            trained_dhmm_bnet.CPD{1} = tabular_CPD(trained_dhmm_bnet, 1, 'CPT', ones(1, length(init)) / length(init));
            trained_dhmm_bnet.CPD{2} = trained_hmm_bnet.CPD{2};
            trained_dhmm_bnet.CPD{3} = prior_dhmm_bnet.CPD{3};
        end
        hmm_emissions = struct(trained_hmm_bnet.CPD{2});

        %infer power (viterbi)
        evidence(3,:) = num2cell(total_consumption);
        [mpe] = my_viterbi_diff(trained_dhmm_bnet, evidence, 1, likelihood_threshold);
        means = hmm_emissions.mean;
        result.consumption(resCounter, :) = means(cell2mat(mpe(1,:)));
        resCounter = resCounter + 1;

    end
    result.appliance_names = getApplianceNames(appliances);
end


    




