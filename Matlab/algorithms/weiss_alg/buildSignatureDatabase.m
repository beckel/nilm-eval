% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [sig_database] = buildSignatureDatabase(setup, trainingDays)

    % load parameters of algorithm
    dataset = setup.dataset;
    household = setup.household;
    granularity = setup.granularity;
    filteringMethod = setup.filtering;
    filtLength = setup.filtLength;
    plevelMinLength = setup.plevelMinLength;
    maxEventDuration = setup.maxEventDuration;
    appliance = setup.appliance;
    
    % set variables
    edgeThreshold = 2;
    
    sig_database = struct;
    numOfSignatures = 1;
    for phase = 1:3   
        
        % get appliance consumption
        appliances = getAppliancesOfPhase(dataset, household, phase);
        
        % get real, apparent and reactive (distortive and translative
        % component) power
        power = getPower(dataset, household, trainingDays, granularity, phase);

        for applianceID = appliances'
            
            appliance_name = getApplianceNames(applianceID);
%             if strcmp(appliance, 'all') ~= 1 && strcmp(appliance, appliance_name) ~= 1
%                 continue;
%             end
            
%             applianceID = getApplianceID(appliance);
%             phase = getPhase(household, applianceID, dataset)
%             [event_vecs, timeOfEvents] = get_events_of_single_phase_appliance(phase, input_params);

            % apply filter to appliance consumption data and get edges 
            appliance_consumption = read_plug_data(dataset, household, applianceID, trainingDays, granularity);
            function_handle = str2func(filteringMethod);
            appliance_consumption_filtered = function_handle(appliance_consumption, filtLength);
            [rows, cols] = find(abs(diff(appliance_consumption_filtered)) > edgeThreshold);
            edges = sparse(rows, cols, ones(length(rows),1), 1, size(appliance_consumption_filtered,2)-1);

            % get power levels (period between two edges with similar power values)
            [plevel] = getPowerLevelsStartAndEndTimes(edges, plevelMinLength);       
            if isempty(plevel.startidx)
                continue;
            end

            % get componentwise(true power, reactive power, distortive power) start and end mean of each selected power level
            plevel = getPowerLevelProperties(plevel, power, plevelMinLength);

            % extract events (between two power levels)
            event_vecs = zeros(length(plevel.startidx)-1, 3);
            numOfEvents = 0;
            threshold_diff_on_off = getThresholdDiffOnOff(applianceID);
            for i = 1:length(plevel.startidx)-1
                if abs(plevel.mean.end(i,1) - plevel.mean.start(i+1,1)) > threshold_diff_on_off && plevel.startidx(i+1) - plevel.endidx(i) < maxEventDuration
                    numOfEvents = numOfEvents + 1;
                    event_vecs(numOfEvents, :) = plevel.mean.start(i+1, 1:3) - plevel.mean.end(i, 1:3);
                end
            end
            event_vecs = event_vecs(1:numOfEvents, :);

            % build mean of positive and negative difference vectors, remove outliers first
            idx_neg = event_vecs(:,1) < 0;
            idx_pos = event_vecs(:,1) > 0;
            
            numOfDims = 2;
            for idx = [idx_neg, idx_pos]
                bic = zeros(ceil(sqrt(nnz(idx)/2)),1);
                %bic2 = zeros(ceil(sqrt(nnz(idx)/2)),1);
                if nnz(idx) > 1 
                    % apply k-means clustering to positive and negative
                    % events, k is selected dynamically
                    for k = 1:ceil(sqrt(nnz(idx)/2))
                        first_k_indexes = find(idx == 1, k, 'first');
                        [~, ~, distances] = kmeans(event_vecs(idx, 1:numOfDims), k, 'emptyaction', 'singleton', 'start', event_vecs(first_k_indexes, 1:numOfDims));
                        log_likelihood = -sum(distances);
                        bic(k,1) = k*numOfDims*log(nnz(idx)) - 2*log_likelihood;
                        %[~, bic2(k,1)] = aicbic(log_likelihood, k*numOfDims, nnz(idx));
                    end
                    [~, numOfClusters] = min(bic);
                    first_k_indexes = find(idx == 1, numOfClusters, 'first');
                    [IDX, centers, ~] = kmeans(event_vecs(idx, 1:numOfDims), numOfClusters, 'emptyaction', 'singleton', 'start', event_vecs(first_k_indexes, 1:numOfDims));
                    
                    % generate signatures out of the cluster centroids
                    bincounts = histc(IDX, 1:numOfClusters);
                    [~, sorted_idx] = sort(bincounts, 'descend');
                    cluster_frequency = bincounts./sum(bincounts);
                    idx_over_30_percent = cluster_frequency > 0.3;
                    for i = 1:max(1,nnz(idx_over_30_percent))
                        sig_database.signatures(numOfSignatures, :) = centers(sorted_idx(i),:);
                        sig_database.phases(numOfSignatures, 1) = phase;
                        sig_database.names{numOfSignatures} = cell2mat(appliance_name);
                        numOfSignatures = numOfSignatures + 1;
                    end
                end         
            end
        end

    end

end

