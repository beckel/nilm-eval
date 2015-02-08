% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [result] = weiss(evaluation_and_training_days, setup, fid)

    % load parameters of algorithm
    dataset = setup.dataset;
    household = setup.household;
    granularity = setup.granularity;
    filteringMethod = setup.filtering;
    filtLength = setup.filtLength;
    plevelMinLength = setup.plevelMinLength;
    maxEventDuration = setup.maxEventDuration;
    eventPowerStepThreshold = setup.eventThreshold;
    r = setup.r;
    evaluation_days = evaluation_and_training_days{1};
    training_days = evaluation_and_training_days{2};
    appliance = setup.appliance;
    
    % set variables
    edgeThreshold = 2;

    % build signature database 
    signature_database = buildSignatureDatabase(setup, training_days);
    signatures = signature_database.signatures;
    names_of_signatures = signature_database.names;
    phases_of_signatures = signature_database.phases;
    
    % calculate length (2-norm) of each signature
    numOfSignatures = size(signatures,1);
    signatureLength = zeros(numOfSignatures,1);
    for j = 1:numOfSignatures
        signatureLength(j,1) = norm(signatures(j,:)); 
    end

    % write signatures to text file
    fprintf(fid,'%20s %13s %16s %9s\n', 'appliance:', 'true power:', 'reactive power:', 'phase:');
    for i = 1:size(signatures,1)
        fprintf(fid,'%20s %13.2f %16.2f %9s\n', cell2mat(names_of_signatures(i)), signatures(i,1),...
             signatures(i,2), num2str(phases_of_signatures(i,1)));
    end
    fprintf(fid, '\n\n'); 

    result = struct;
    result.events = [];    
    signatures_in_previous_phases = 0;
    
    for phase = 1:3
        
        % get real, apparent and reactive (distoritve and translative
        % component) power
        power = getPower(dataset, household, evaluation_days, granularity, phase);

        % apply filter to normalized apparent power and get edges 
        function_handle = str2func(filteringMethod);
        normalized_apparent_power_filtered = function_handle(power.normalized_apparent, filtLength);
        [rows, cols] = find(abs(diff(normalized_apparent_power_filtered)) > edgeThreshold);
        edges = sparse(rows, cols, ones(length(rows),1), 1, size(normalized_apparent_power_filtered,2)-1);

        % get power levels (period between two edges with similar power values)
        [plevel] = getPowerLevelsStartAndEndTimes(edges, plevelMinLength);       
        if isempty(plevel.startidx)
            continue;
        end

        % get characteristics of power levels
        plevel = getPowerLevelProperties(plevel, power, plevelMinLength);

        % generate event vectors by taking the diffference between two consecutive power levels
        event_vecs = zeros(length(plevel.startidx)-1, 4);
        eventIsValid = zeros(length(plevel.startidx), 1);
        numOfEvents = 0;
        for i = 1:length(plevel.startidx)-1
               if abs(plevel.mean.end(i,1) - plevel.mean.start(i+1,1)) > eventPowerStepThreshold && plevel.startidx(i+1) - plevel.endidx(i) < maxEventDuration
                    eventIsValid(i) = 1;
                    numOfEvents = numOfEvents + 1;
                    event_vecs(numOfEvents, 1:3) = plevel.mean.start(i+1, :) - plevel.mean.end(i, :);
                    max_std_true_power = max(plevel.std(i,1), plevel.std(i+1,1));
                    max_std_reactive_power = max(plevel.std(i,2), plevel.std(i+1,2));
                    oscillationTerm = norm([max_std_true_power, max_std_reactive_power]);
                    event_vecs(numOfEvents, 4) = oscillationTerm;
               end
        end
        event_vecs = event_vecs(1:numOfEvents, :);
        timeOfEvents = plevel.endidx(eventIsValid==1)'; 

        % assign each event to its best match in the signature database
        [signatureIDs, dist] = knnsearch(signatures(phases_of_signatures == phase, 1:2), event_vecs(:,1:2));        
        if ~isempty(signatureIDs)
            dist_threshold = r*signatureLength(signatureIDs,1) + event_vecs(:,4);
            matching_valid = dist < dist_threshold;
            signatureIDs = signatureIDs + signatures_in_previous_phases;
            result.events = [result.events; timeOfEvents(matching_valid), signatureIDs(matching_valid), event_vecs(matching_valid, 1:3)];
            signatures_in_previous_phases = signatures_in_previous_phases + nnz(phases_of_signatures == phase);
        end
    end

    % store labeled events
    result.event_names = {};
    for i = 1:length(names_of_signatures)
        if ismember(cell2mat(names_of_signatures(i)), result.event_names)
            result.events(result.events(:,2) == i,2) = find(ismember(result.event_names, names_of_signatures{i}));
        else
            result.event_names{end+1} = cell2mat(names_of_signatures(i));
            result.events(result.events(:,2) == i,2) = length(result.event_names);
        end
    end

end

