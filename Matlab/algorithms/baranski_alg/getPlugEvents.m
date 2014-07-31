% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [plugEventsList] = getPlugEvents(house, evaluation_days, setup)

    % extract events of the ground truth data (plug-level data)
    
    % load parameters
    threshold = setup.threshold;
    granularity = setup.granularity;
    dataset = setup.dataset;
    
    % get appliances of house
    appliances = findAppliances(house, setup.dataset);

    idx = 1;
    plugEventsList = [];
    for appliance = appliances
        plug_consumption = read_plug_data(dataset, house, appliance, evaluation_days, granularity);
        events = getEvents(plug_consumption', threshold);
        events = [events, repmat(appliance, size(events,1), 1)];
        plugEventsList = [plugEventsList; events];
        idx = idx + 1;
    end

end

