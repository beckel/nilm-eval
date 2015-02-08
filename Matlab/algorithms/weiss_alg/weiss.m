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
    osc = setup.osc;
    evaluation_days = evaluation_and_training_days{1};
    training_days = evaluation_and_training_days{2};
    appliance = setup.appliance;
    
    % set variables
    edgeThreshold = 2;
    num_measurements = size(evaluation_days,1)*86400;

    % build signature database 
    global caching;
    if caching == 1
        if exist('cache_sigdat.mat') == 2
            load('cache_sigdat');
        else
            signature_database = buildSignatureDatabase(setup, training_days);
            save('cache_sigdat', 'signature_database');
        end
    else
        signature_database = buildSignatureDatabase(setup, training_days);        
    end
    
    signatures = signature_database.signatures;
    names_of_signatures = signature_database.names;
    phases_of_signatures = signature_database.phases;
    % calculate length (2-norm) of each signature
    numOfSignatures = size(signatures,1);
    signatureLength = zeros(numOfSignatures,1);
    for j = 1:numOfSignatures
        signatureLength(j,1) = norm(signatures(j,:)); 
    end
    signature_database.signatureLength = signatureLength;
    
    % write signatures to text file
    fprintf(fid,'%20s %13s %16s %9s\n', 'appliance:', 'true power:', 'reactive power:', 'phase:');
    for i = 1:size(signatures,1)
        fprintf(fid,'%20s %13.2f %16.2f %9s\n', cell2mat(names_of_signatures(i)), signatures(i,1),...
             signatures(i,2), num2str(phases_of_signatures(i,1)));
    end
    fprintf(fid, '\n\n'); 

    result = struct;
    result.events = [];  
    result.appliance_names = {};
    
    input_params = struct;
    input_params.dataset = dataset;
    input_params.household = household;
    input_params.evaluation_days = evaluation_days;
    input_params.granularity = granularity;
    input_params.filtering_method = filteringMethod;
    input_params.filtLength = filtLength;
    input_params.edgeThreshold = filtLength;
    input_params.plevelMinLength = plevelMinLength;
    input_params.eventPowerStepThreshold = eventPowerStepThreshold;
    input_params.maxEventDuration = maxEventDuration;
    
    % Disaggregate all appliances or individual appliance?
    if strcmp(appliance, 'Stove') == 1
        [events, times] = get_events_of_multi_phase_appliance(input_params);
        matching_ids = find(strcmp(signature_database.names, 'Stove'));
        stove_sig = signatures(matching_ids,:);
        result = infer_events_stove(result, events, times, min(stove_sig(stove_sig > 0))-200);
        [result.usage, result.usage_times_start] = infer_usage(appliance, result.events(:,3), result.events(:,1), num_measurements, setup.usage_duration);
        result.consumption = infer_consumption_stove(result.events(:,3), result.events(:,1), num_measurements, setup.usage_duration);

    elseif strcmp(appliance, 'Dishwasher') == 1
        applianceID = getApplianceID(appliance);
        phase = getPhase(household, applianceID, dataset);
        [events, times] = get_events_of_single_phase_appliance(phase, input_params);
        result = infer_events(result, events, times, signature_database, phase, setup, appliance);
        [result.usage, result.usage_times_start] = infer_usage(appliance, result.events(:,3), result.events(:,1), num_measurements, setup.usage_duration);
        result.consumption = infer_consumption(result, evaluation_and_training_days, setup.usage_duration, appliance, setup);

    elseif strcmp(appliance, 'Water kettle') == 1 || strcmp(appliance, 'TV') == 1 || strcmp(appliance, 'Stereo') == 1
            applianceID = getApplianceID(appliance);
            phase = getPhase(household, applianceID, dataset);
            [events, times] = get_events_of_single_phase_appliance(phase, input_params);
            result = infer_events(result, events, times, signature_database, phase, setup, appliance);
            [result.usage, result.usage_times_start] = infer_usage(appliance, result.events(:,3), result.events(:,1), num_measurements, setup.usage_duration);
            result.consumption = infer_consumption(result, evaluation_and_training_days, setup.usage_duration, appliance, setup);
    elseif strcmp(appliance, 'Fridge') == 1 || strcmp(appliance, 'Freezer') == 1
            applianceID = getApplianceID(appliance);
            phase = getPhase(household, applianceID, dataset);
            [events, times] = get_events_of_single_phase_appliance(phase, input_params);
            result = infer_events(result, events, times, signature_database, phase, setup, appliance);
            result.consumption = infer_consumption(result, evaluation_and_training_days, setup.usage_duration, appliance, setup);
    elseif strcmp(appliance, 'Laptop') == 1
            applianceID = getApplianceID(appliance);
            phase = getPhase(household, applianceID, dataset);
            [events, times] = get_events_of_single_phase_appliance(phase, input_params);
            result = infer_events(result, events, times, signature_database, phase, setup, appliance);
%             result.consumption = infer_consumption(result, evaluation_and_traini            
    elseif strcmp(appliance, 'All')

        %% "Old": all appliances
        signatures_in_previous_phases = 0;
        for phase = 1:3
            if caching == 1
                error('Does not work with caching - run without caching');
            end
           [event_vecs, timeOfEvents] = get_events_of_single_phase_appliance(phase, input_params);
            % assign each event to its best match in the signature database
            [signatureIDs, dist] = knnsearch(signatures(phases_of_signatures == phase, 1:2), event_vecs(:,1:2));        
            if ~isempty(signatureIDs)
                dist_threshold = r*signatureLength(signatureIDs,1) + event_vecs(:,4);
                matching_valid = dist < dist_threshold;
                %% should te next line not be earlier???
                signatureIDs = signatureIDs + signatures_in_previous_phases;
                result.events = [result.events; timeOfEvents(matching_valid), signatureIDs(matching_valid), event_vecs(matching_valid, 1:3)];
                signatures_in_previous_phases = signatures_in_previous_phases + nnz(phases_of_signatures == phase);
            end
        end
        
    else
        error('Appliance not supported');
    end
    
    % store labeled events
    for i = 1:length(names_of_signatures)
        if ismember(cell2mat(names_of_signatures(i)), result.appliance_names)
            result.events(result.events(:,2) == i,2) = find(ismember(result.appliance_names, names_of_signatures{i}));
        else
            % do nothing if signature is not in signature database
            % result.appliance_names{end+1} = cell2mat(names_of_signatures(i));
            % result.events(result.events(:,2) == i,2) = length(result.appliance_names);
        end
    end        
end

