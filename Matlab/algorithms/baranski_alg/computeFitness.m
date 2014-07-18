% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [fitnessValues] = computeFitness(clusters, clusterSizes, population, numOfClusters, fitnessWeights)

    % compute fitness value of each finite state machine

    clusterPower = clusters(:, 1);
    fitnessValues = zeros(size(population, 1), 1);
    for i=1:size(population,1)
        clustersUsed = population(i, :);
        Q1 = abs(sum(clusterPower(clustersUsed')))/max(abs(clusterPower(clustersUsed')));
        clusterFrequencies = clusterSizes./sum(clusterSizes);
        Q2 = abs(sum(clusterPower(clustersUsed').*clusterFrequencies(clustersUsed)))/max(abs(clusterPower(clustersUsed')));
        Q3 = nnz(clustersUsed)/numOfClusters;
        fitnessValues(i) = fitnessWeights * [Q1; Q2; Q3]; 
    end
end

