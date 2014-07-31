% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [best_clustersOfFsm] = find_best_variation(events_FSMs_matrix, clusterOfEvents, valid_cluster_permutations, fsm_idx, events, maxSequenceLength)

    best_deviation_from_median = intmax;
    best_clustersOfFsm = valid_cluster_permutations(1,:);

    for variation = 1:size(valid_cluster_permutations)
        clustersOfFsm = valid_cluster_permutations(variation, :);
        for i=1:length(clustersOfFsm)
            eventsOfFsm = clusterOfEvents == clustersOfFsm(1,i);
            events_FSMs_matrix(eventsOfFsm, fsm_idx) = i; 
        end   
        
        % build event sequences of a finte state machine 
        sequencesOfFsm = buildSequences(events_FSMs_matrix, events, fsm_idx, maxSequenceLength);
        events_FSMs_matrix(eventsOfFsm, fsm_idx) = 0;
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
        
        if sum(quality) < best_deviation_from_median
            best_clustersOfFsm = valid_cluster_permutations(variation, :);
            best_deviation_from_median = deviation_from_median;
        end
    end


end

