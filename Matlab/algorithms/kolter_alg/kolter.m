% This file is part of the following project:
% J. Zico Kolter. Tommi Jaakkola.
% Approximate Inference in Additive Factorial HMMs with Application to Energy Disaggregation.
% In: International Conference on Artificial Intelligence and Statistics (AISTATS). 2012.
% Code provided as supplementary material
% Copyright: J. Zico Kolter, MIT CSAIL, 2014.

% Modified by Romano Cicchetti, ETH Zurich, in the context of the NILM-Eval project

function [data] = kolter(days, setup, fid)

    % load parameters
    dataset = setup.dataset;
    interval = setup.granularity;
    household = setup.household;
    lratio = setup.filtLRatio;
    
    % set variables
    edgeThreshold = 5;
    plevelMinLength = 5;

    % get total power consumption
    evaluation_days = days{1};
    true_power = read_smartmeter_data(dataset, num2str(household, '%02d'), evaluation_days, interval, 'powerallphases');

    % total variation denoising
    lmax = tvdiplmax(true_power);
    [data, ~, ~] = tvdip(true_power, lmax*lratio, 1, 1e-3, 100);
    data = data';
    
    % generate power levels
    plevel = generatePlevels(edgeThreshold, plevelMinLength, data, true_power); 
    
    % generate snippets from power levels
    snippets = generateSnippetsFromPlevels(plevel);
    
    % generate HMMs from snippets
    HMMs = generateHMMsFromSnippets(snippets);
    
    % calculate probability of one snippet generating another
    numOfSnippets = length(snippets.mean);
    probsBetweenAllSnippets = zeros(numOfSnippets, numOfSnippets);
    for i = 1:numOfSnippets
        log_trans = log(cell2mat(HMMs.transition(i)));
        mu = cell2mat(HMMs.mean(i));
        sigma = cell2mat(HMMs.std(i));
        numOfStates = length(cell2mat(snippets.mean(i))) + 1;
        for j = 1:numOfSnippets
            if numOfStates ~= length(cell2mat(snippets.mean(j))) + 1 
                continue;
            end
            firstPlevelOfSnippet = snippets.start(j);
            lastPlevelOfSnippet = snippets.end(j);
            observation = data(plevel.startidx(firstPlevelOfSnippet):plevel.endidx(lastPlevelOfSnippet)) - ...
                plevel.mean(firstPlevelOfSnippet - 1);
            emit = zeros(numOfStates, length(observation));
            for state = 1:numOfStates
                emit(state, :) = normpdf(observation, mu(state), sigma(state));
            end
            log_emit = log(emit);
            
            maxProb = zeros(numOfStates, length(observation));
            maxProb(:,1) = log(0);
            maxProb(1,1) = log(1);
            for t = 2:length(observation)
                for k = 1:numOfStates
                    sum = maxProb(:,t-1) + log_trans(:,k) + log_emit(k,t);
                    maxProb(k,t) = max(sum);
                end 
                if all(isinf(maxProb(:,t)))
                    break;
                end
            end
            probsBetweenAllSnippets(i,j) = max(maxProb(:,length(observation)));
        end
    end

    % build adjacency Matrix from k-nearest neighbor graph
    numOfStatesOfSnippets = cellfun(@length, HMMs.mean);
    mu = {};
    P = {};   
    for numOfStates = 2:5
        idxOfHMMs = find(numOfStatesOfSnippets == numOfStates);
        meansOfHMMs = HMMs.mean(idxOfHMMs);
        transitionOfHMMs = HMMs.transition(idxOfHMMs);
        probsBetweenSelectedSnippets = probsBetweenAllSnippets(idxOfHMMs, idxOfHMMs);
        adjacencyMatrix = zeros(size(probsBetweenSelectedSnippets));
        for i = 1:length(idxOfHMMs)
            idx_nonzero = find(probsBetweenSelectedSnippets(:,i) ~= 0);
            numSnippets = length(idx_nonzero);
            if numSnippets == 0
                continue;
            end
             [~,sortedIdx] = sort(probsBetweenSelectedSnippets(idx_nonzero,i), 'descend');
            sortedIdx = sortedIdx(1:1+floor(numSnippets/4));
            adjacencyMatrix(idx_nonzero(sortedIdx),i) = 1;
        end

        numOfClusters = floor(sqrt(length(idxOfHMMs)/2));
        if numOfClusters == 0
            continue;
        end
        clusters = SpectralClustering(adjacencyMatrix, numOfClusters, 1);
        
        for cl = 1:numOfClusters
            idx = clusters(:,cl) == 1;
            selectedMeans = cell2mat(meansOfHMMs(idx)');       
            mu{end+1} = mean(selectedMeans,2)';
            selectedTrans = transitionOfHMMs(idx);
            Trans = cat(3,selectedTrans{:});
            P{end+1} = mean(Trans,3);
        end
    end
    
    % write cluster centorids (HMMs) to text file
    fprintf(fid,'%20s\n', 'MEANS:');
    for i = 1:length(mu)
        fprintf(fid, '%f\t', cell2mat(mu(i))); 
        fprintf(fid, '\n');
    end
    
    % run AFAMAP algorithm
    n = 1;
    paramsAfamap = struct;
    paramsAfamap.max_iter = 1;
    paramsAfamap.lambda = Inf;
    paramsAfamap.dlambda = Inf;
    paramsAfamap.dSig = var(diff(data));
    paramsAfamap.Sig = var(data);
    [X0,Z,G] = myAfamap(plevel.mean', plevel.duration', mu, P, paramsAfamap);
        
end

