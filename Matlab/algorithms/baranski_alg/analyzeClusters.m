% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [frequencyOfPlugEventsInCluster] = analyzeClusters(clusters, clusterOfEvents, events, evaluation_days, setup)

    % analyze the clusters (to which appliances belong the events)

    household = setup.household;

    appliances = findAppliances(household, setup.dataset);
    frequencyOfPlugEventsInCluster = zeros(size(clusters,1),length(appliances));
    for cluster = 1:size(clusters,1)
        clusterEventsList = find(clusterOfEvents == cluster);
        plugEventsList = getPlugEvents(household, evaluation_days, setup);
        plugEventsEndTime = plugEventsList(:,4) + plugEventsList(:,3);
        a = zeros(1,size(clusterEventsList,2));
        for i = 1:size(clusterEventsList,2)
            event_idx = clusterEventsList(1,i);
            valid_plug_events = ((plugEventsList(:,4)+3 >= events(event_idx,4)) & (plugEventsList(:,4)-3 <= events(event_idx,4) + events(event_idx,3))) ...
                | ((plugEventsEndTime + 3 >= events(event_idx,4)) &  (plugEventsEndTime -3 <= events(event_idx,4) + events(event_idx,3)));
            if (nnz(valid_plug_events) == 1)
                a(1,i) = plugEventsList(valid_plug_events,5);
            end
        end
        bincounts = histc(a, appliances);
        frequency = bincounts./size(a,2);
        frequencyOfPlugEventsInCluster(cluster, :) = frequency;
    end
end

