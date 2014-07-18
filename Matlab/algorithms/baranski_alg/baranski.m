% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [summary] = baranski(evaluation_and_training_days, setup, fid)

    % load parameters
    dataset = setup.dataset;
    household = setup.household;
    granularity = setup.granularity;
    numOfClusters = setup.numOfClusters;
    threshold = setup.threshold;
    maxSequenceLength = setup.maxSeqLength / granularity;
    numOfFSMs = setup.numOfFSMs;
    maxNumOfStates = setup.maxNumOfStates;
    dimWeights = [setup.dim1Weight, setup.dim2Weight, setup.dim3Weight];
    fitnessWeights = [setup.fitWeight1, setup.fitWeight2, setup.fitWeight3];

    % get total consumption data
    evaluation_days = evaluation_and_training_days{1};
    total_consumption = read_smartmeter_data(dataset, num2str(household, '%02d'), evaluation_days, granularity, 'powerallphases');
    
    % get events (change in power > threshold) and cluster them using a fuzzy c-means clustering algorithm
    clusters = []; 
    events = getEvents(total_consumption', threshold);
    U = zeros(numOfClusters, size(events, 1));
    idx_pos = events(:,1) > 0;
    idx_neg = events(:,1) < 0;
    iter = 1;
    for idx = [idx_pos, idx_neg]
        [normalizedEvents, mu, sigma] = zscore(events(idx,1:3));
        normalizedEvents = bsxfun(@times, normalizedEvents, dimWeights);
        [cl, U_idx, ~] = my_fcm(normalizedEvents, numOfClusters/2, [2; 100; 1e-5; 0]);
        cl = bsxfun(@times, cl, 1./dimWeights);
        mu_vec = repmat(mu, numOfClusters/2, 1);
        sigma_vec = repmat(sigma, numOfClusters/2, 1);
        cl = cl .*sigma_vec + mu_vec;
        clusters = [clusters;cl];
        s = (iter-1)*numOfClusters/2 + 1;
        e = iter*numOfClusters/2;
        U(s:e, idx) = U_idx;
        iter = iter + 1;
    end


    % assign each event to the most likely cluster and afterwards get the size of each cluster
    [~, clusterOfEvents] = max(U);
    [~, idx2] = unique(sort(clusterOfEvents));
    clusterSizes = diff([idx2; size(clusterOfEvents,2)]);

    % analyze the clusters (to which appliances belong the events) 
    frequencyOfPlugEventsInCluster = analyzeClusters(clusters, clusterOfEvents, events, evaluation_days, setup);

    % write to text file
    writeParametersToTxt(household, frequencyOfPlugEventsInCluster, events, clusters, clusterSizes, clusterOfEvents, fid)

    % generate finite state machines that correspond to potential appliances
    FSMs = generateFSMs(clusters, numOfClusters, clusterSizes, numOfFSMs, fitnessWeights, maxNumOfStates);

    events_FSMs_matrix = zeros(size(events,1), size(FSMs,1));
    numFSMs = 0;
    validFSMs = [];
    for fsm_idx = 1:size(FSMs,1)
        % get all variations of the finite state machine and save the valid
        % variations
        all_cluster_permutations = perms(FSMs(fsm_idx,:));
        valid_idx = ones(size(all_cluster_permutations,1),1);
        for i = 1:size(all_cluster_permutations,1)
            if any(cumsum(clusters(all_cluster_permutations(i,:),1)) < -10)
                valid_idx(i,1) = 0;
            end
        end
        valid_cluster_permutations = all_cluster_permutations(valid_idx==1,:);
        if isempty(valid_cluster_permutations)
            continue;
        else
            clustersOfFsm = valid_cluster_permutations(1,:);
            clustersOfFsm = find_best_variation(events_FSMs_matrix, clusterOfEvents, valid_cluster_permutations, fsm_idx, events, maxSequenceLength);
        end
        numFSMs = numFSMs+1;
        validFSMs(end+1) = fsm_idx;

        % print finite state machines to text file
        fprintf(fid,'%10s\n', strcat('fsm_', num2str(fsm_idx)));
        fprintf(fid,'%12.0f\n', clusters(clustersOfFsm,1)'); 


        %get all events belonging to the finite state machine 
        for i=1:length(clustersOfFsm)
            eventsOfFsm = clusterOfEvents == clustersOfFsm(1,i);
            events_FSMs_matrix(eventsOfFsm, fsm_idx) = i; 
        end   
    end

    conflictsExist = 1;
    while conflictsExist
        events_selected = zeros(size(events_FSMs_matrix,1),1);
        sequences_of_all_FSMs = [];
        counter = 1;
        for fsm_idx = validFSMs
            % build event sequences of a finte state machine 
            sequencesOfFsm = buildSequences(events_FSMs_matrix, events, fsm_idx, maxSequenceLength);
            if isempty(sequencesOfFsm) 
                continue;
            end

            % compute median duration of all event sequences that have a high
            % probability of belonging to the shortest path
            duration_of_sequences = events(sequencesOfFsm(:,2),4) - events(sequencesOfFsm(:,1),4);
            if nnz(sequencesOfFsm(:,3) == 1) > 1
                median_duration_of_sequences = median(duration_of_sequences(sequencesOfFsm(:,3) == 1,1));
            else
                median_duration_of_sequences = median(duration_of_sequences(:,1));
            end

            % build directed graph with event sequences as nodes and
            % compute the shortest path
            [directed_graph] = buildGraph(sequencesOfFsm, duration_of_sequences, median_duration_of_sequences);
            num_of_sequences = size(sequencesOfFsm,1);
            [~, path, ~] = graphshortestpath(directed_graph, 1, num_of_sequences, 'Method', 'Bellman-Ford');
            median_duration_of_sequences_on_path = median(duration_of_sequences(path, 1));
            deviation_from_median = abs((duration_of_sequences(path, 1) - median_duration_of_sequences_on_path)/median_duration_of_sequences_on_path);
            quality = deviation_from_median .* log(deviation_from_median);
            quality(isnan(quality)) = -10; 
            sequences_of_all_FSMs = [sequences_of_all_FSMs; sequencesOfFsm(path,1:2), quality, ...
                repmat(fsm_idx, size(path,2), 1)];

            events_on_path = sequencesOfFsm(path, 1:2);
            events_selected(events_on_path(:),1) = events_selected(events_on_path(:),1) + 1;
            counter = counter + 1;
        end 

        fprintf(fid, '\nunassigned_events: %5.0f; assigned_events: %5.0f, conflict_events: %5.0f\n', nnz(events_selected == 0), ...
            nnz(events_selected == 1), nnz(events_selected > 1));  

        % solve conflicts (events assigned to more than one finite state
        % machine)
        [events_FSMs_matrix, conflictsExist] = solveConflicts(events_selected, sequences_of_all_FSMs, events_FSMs_matrix, conflictsExist); 
    end

    summary = struct; % dummy output
end

