function [ result ] = infer_events(result, events, times, signature_database, phase, setup, appliance_name)

    r = setup.r;
    osc = setup.osc;
    
    signatures = signature_database.signatures;
    signatures_on_phase = signatures(signature_database.phases == phase, 1:2);
    signatureLength = signature_database.signatureLength(signature_database.phases == phase);
    signatureNames = signature_database.names(signature_database.phases == phase);
    
    signatures_previous_phases = 0;
    if phase == 2
        signatures_previous_phases = signatures_previous_phases + sum(signature_database.phases < 2);
    elseif phase == 3
        signatures_previous_phases = signatures_previous_phases + sum(signature_database.phases < 3);
    end
    
    % assign each event to its best match in the signature database
    [signatureIDs, dist] = knnsearch(signatures_on_phase, events(:,1:2));        
    if ~isempty(signatureIDs)
        dist_threshold = r*signatureLength(signatureIDs,1) + osc*events(:,4);
        matching_valid = dist < dist_threshold;
        matching_ids = find(strcmp(signatureNames, appliance_name));
        matching_valid = matching_valid & ismember(signatureIDs, matching_ids);
        result.events = [result.events; times(matching_valid), signatureIDs(matching_valid) + signatures_previous_phases, events(matching_valid, 1:3)];
        result.appliance_names{end+1} = appliance_name;
    end
end

