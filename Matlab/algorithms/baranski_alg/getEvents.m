% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [events] = getEvents(total_consumption, threshold)

% extract events

% define parameters and data structures 
eventsTotalStep = zeros(length(total_consumption), 1);
eventsMaxStep = zeros(length(total_consumption), 1);
eventsDuration = ones(length(total_consumption), 1);
eventsStartTime = ones(length(total_consumption), 1);
maxEventDuration = 20; % maximum duration of an event in seconds
minEventDuration = 5;
delta_p_prev = 0;      % previous difference between two consecutive power values
p_t_prev = 0;          % previous power value
index = 0;             % index of an event
startTime = 1;         % start time of an event

% for each time step
for i = 1:length(total_consumption)
    p_t = total_consumption(i, 1);
    delta_p = p_t - p_t_prev;
    
    % a power step between two consecutive power values is ignored if the 
    % difference between the two power values is smaller than a threshold
    if (abs(delta_p) > threshold)
        signsEqual = sign(delta_p) == sign(delta_p_prev);
        if (( i - startTime > maxEventDuration || ~signsEqual) && (i - startTime > minEventDuration || startTime == 1))
            % create a new event and assign power step to it
            index = index + 1;
            startTime = i;
            eventsStartTime(index) = startTime;
            delta_p_prev = delta_p;
        end
        
        % update/initialized maximum power step of the existing/new event 
        % if necessary
        if (abs(delta_p) > abs(eventsMaxStep(index)))
            eventsMaxStep(index) = delta_p;
        end
        % update/initialize duration and total power step of the existing/new   
        % event
        eventsDuration(index) = i - startTime + 1; 
        eventsTotalStep(index) = eventsTotalStep(index) + delta_p;    
    end
    p_t_prev = p_t;
end

% cut the event data structures to only include the extracted events
eventsTotalStep = eventsTotalStep(1:index, 1);
eventsMaxStep = eventsMaxStep(1:index, 1);
eventsDuration = eventsDuration(1:index, 1);
eventsStartTime = eventsStartTime(1:index, 1);
events = [eventsTotalStep, eventsMaxStep, eventsDuration, eventsStartTime];
wrong_sign_idx = sign(events(:,1)) ~= sign(events(:,2));
events(wrong_sign_idx,2) = -1*events(wrong_sign_idx,2);
idx_over_10 = abs(eventsTotalStep(:,1)) > 5;
events = events(idx_over_10, :);
end

