% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [directed_graph] = buildGraph(sequencesOfFsm, duration_of_sequences, median_duration_of_sequences)

    % build directed graph with event sequences as nodes

    edges_start = [];
    edges_end = [];
    edges_weight = [];
    num_of_sequences = size(sequencesOfFsm,1);
    for idx_sequence = 1:num_of_sequences-1
        off_event = sequencesOfFsm(idx_sequence,2);
        possible_neighbor_sequences = sequencesOfFsm(:,1) > off_event;
        if nnz(possible_neighbor_sequences) == 0
            continue;
        end
        neighbor_sequences = possible_neighbor_sequences & sequencesOfFsm(:,1) < min(sequencesOfFsm(possible_neighbor_sequences,2));
        sequence_deviation_from_median = abs(duration_of_sequences(idx_sequence,1) - median_duration_of_sequences);
        weight_of_sequence = sequence_deviation_from_median*log(sequence_deviation_from_median);
        if isnan(weight_of_sequence)
            weight_of_sequence = 0.001;
        end
        neighbors_deviation_from_median = abs(duration_of_sequences(neighbor_sequences ==1,1) - median_duration_of_sequences);
        weight_of_neighbor_sequences = neighbors_deviation_from_median.*log(neighbors_deviation_from_median);
        weight_of_neighbor_sequences(isnan(weight_of_neighbor_sequences)) = 0.001;
        edges_start = [edges_start; repmat(idx_sequence,nnz(neighbor_sequences),1)];
        edges_end = [edges_end; find(neighbor_sequences ==1)];
        edges_weight = [edges_weight; weight_of_sequence+weight_of_neighbor_sequences./2];
    end
    directed_graph = sparse(edges_start, edges_end, edges_weight, num_of_sequences, num_of_sequences);
end

