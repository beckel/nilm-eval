% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [] = writeParametersToTxt(house, dataset, frequencyOfPlugEventsInCluster, events, clusters, clusterSizes, clusterOfEvents, fid)

    % write clusters to text file
    
    [~, cl_sorted] = sort(clusterSizes, 'descend');
    appliances = findAppliances(house, dataset);
    appliance_names = getApplianceNames(appliances);
    frequencies = zeros(size(clusters,1), 2);
    fprintf(fid, '%12s %12s %12s %12s %12s %12s %12s %20s %6s %20s %6s\n', 'power:', 'std_power', 'boost', 'std_boost:', 'duration', 'std_duration:', 'size:', 'Appliance1', ...
        'Freq1', 'Appliance2', 'Freq2');
    iter = 1;
    for i = cl_sorted'
        std_power = std(events(clusterOfEvents == i,1));
        std_boost = std(events(clusterOfEvents == i,2));
        std_duration = std(events(clusterOfEvents == i,3));
        [~, sorted_idx] = sort(frequencyOfPlugEventsInCluster(i,:), 'descend');
        frequency1 = frequencyOfPlugEventsInCluster(i,sorted_idx(1));
        frequency2 = frequencyOfPlugEventsInCluster(i,sorted_idx(2));
        frequencies(iter,1) = frequency1;
        frequencies(iter,2) = frequency2;
        appliance_name1 = cell2mat(appliance_names(sorted_idx(1)));
        appliance_name2 = cell2mat(appliance_names(sorted_idx(2)));
        fprintf(fid, '%12.0f %12.0f %12.0f %12.0f %12.0f %12.0f %12.0f %20s %6.2f %20s %6.2f\n', clusters(i,1), std_power, ...
            clusters(i,2), std_boost, clusters(i,3), std_duration, clusterSizes(i,1), ...; 
            appliance_name1,frequency1, appliance_name2, frequency2);
        iter = iter + 1;
    end
    fprintf(fid, 'sum Freq1 = %6.2f;  sum Freq2 = %6.2f\n', sum(frequencies(:,1)), sum(frequencies(:,2)));
    fprintf(fid, '\n%26s\n\n', 'finite state machines:');
    
end

