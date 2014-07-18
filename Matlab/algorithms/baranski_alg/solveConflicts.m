% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [events_FSMs_matrix, conflictsExist] = solveConflicts(events_selected, sequences_of_all_FSMs, events_FSMs_matrix, conflictsExist)

    % solve conflicts (events assigned to more than one finite state
    % machine)
    
    conflict_events_idx = find(events_selected(:,1) > 1);
    if isempty(conflict_events_idx)
        conflictsExist = 0;
        return;
    end
    
    for conflict_event = conflict_events_idx'
        conflict_sequences_idx = sequences_of_all_FSMs(:,1) == conflict_event | sequences_of_all_FSMs(:,2) == conflict_event;
        conflict_sequences = sequences_of_all_FSMs(conflict_sequences_idx, :);
        [~,sortedIdx] = sort(conflict_sequences(:,3));
        winner_fsm = conflict_sequences(sortedIdx(1), 4);
        event_type = events_FSMs_matrix(conflict_event, winner_fsm);
        events_FSMs_matrix(conflict_event, :) = 0;
        events_FSMs_matrix(conflict_event, winner_fsm) = event_type;
    end  
end

