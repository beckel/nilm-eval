% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [ FSMs ] = generateFSMs(clusters, numOfClusters, clusterSizes, numOfFSMs, fitnessWeights, maxNumOfStates)

    % generate finite state machines that correspond to potential appliances
    % select the numOfFSMs finite state machines with the highest fitness
    % values
    
    population = [];
    for i = 2:maxNumOfStates
        population = [population; combnk(1:numOfClusters, i)];
    end
    fitnessValues = computeFitness(clusters, clusterSizes, population, numOfClusters, fitnessWeights);
    [~, sortedIdx] = sort(fitnessValues);
    FSMs = population(sortedIdx(1:numOfFSMs), :);

end

