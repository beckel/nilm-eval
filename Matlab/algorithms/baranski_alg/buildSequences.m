% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [sequencesOfFsm] = buildSequences(events_FSMs_matrix, events, fsm_idx, maxSequenceLength)

    % build event sequences of a finte state machine
    
    on_events_of_fsm = find(events_FSMs_matrix(:,fsm_idx) == 1);
    off_events_of_fsm = find(events_FSMs_matrix(:,fsm_idx) == 2);
    sequencesOfFsm = [];
    for on_event_idx = 1:length(on_events_of_fsm)
        on_event = on_events_of_fsm(on_event_idx);
        off_event_idx = find(off_events_of_fsm > on_event,1,'first');
        while (off_event_idx <= length(off_events_of_fsm))
            off_event = off_events_of_fsm(off_event_idx);
            if events(on_event,4) + maxSequenceLength < events(off_event,4)
                break;
            elseif all(cumsum([events(on_event,1), events(off_event,1)]) > -10) 
                next_on_event = on_events_of_fsm(min(on_event_idx+1, length(on_events_of_fsm)));
                previous_on_event = on_events_of_fsm(max(on_event_idx-1,1));
                next_off_event = off_events_of_fsm(min(off_event_idx+1, length(off_events_of_fsm)));
                previous_off_event = off_events_of_fsm(max(off_event_idx-1,1));
                if events(next_on_event,4) >  events(off_event,4) && events(on_event,4) >  events(previous_off_event,4) && ...
                      events(next_on_event,4) <  events(next_off_event,4) && events(previous_on_event,4) >  events(previous_off_event,4)
                    sequencesOfFsm = [sequencesOfFsm; on_event, off_event, 1];
                else
                    sequencesOfFsm = [sequencesOfFsm; on_event, off_event, 0];
                end
            end 
            off_event_idx = off_event_idx + 1;
        end
    end
end

