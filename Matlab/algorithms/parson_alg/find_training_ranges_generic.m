% This file is part of the following project:
% Oliver Parson, Siddhartha Ghosh, Mark Weal, Alex Rogers.
% Non-intrusive Load Monitoring using Prior Models of General Appliance Types.
% In: 26th AAAI Conference on Artificial Intelligence. Toronto, Canada. 2012.
% Code available for download: https://sites.google.com/site/oliparson/phd-work/research-files/aaai-2012-code.zip?attredirects=0
% Copyright: Oliver Parson et al., University of Southhampton, 2012.

function [ flattened_selected_training_data, window_lls ] = find_training_ranges_generic(downsampled, training_length, prior_bnet, num_of_windows )

fprintf('finding training ranges... ');
progress = 10;
euc_diff_mean = [];
euc_diff_cov = [];

num_results = ((length(downsampled)/training_length) * 2) - 1;
training_ranges = [];
start = 1;
lls = zeros(num_results, 1);
for l=1:length(lls)
    
    if l / length(lls) >= progress / 100
        fprintf('%d%% ', progress);
        progress = progress + 10;
    end
    
    range_start = start;
    range_end = start+training_length-1;
    training_range = range_start:range_end;
    
    start = start + training_length/2;

    % find a model that best explains observations
    training_data = diff(downsampled(training_range));
    try 
        [trained_bnet, lls(l)] = learn_params_generic(prior_bnet, training_data);

        % if the model can plausibly explain observations
         if lls(l) > -2000
            prior_bnet_CPD = struct(prior_bnet.CPD{4});
            trained_bnet_CPD = struct(trained_bnet.CPD{4});

            euc_diff_mean = [euc_diff_mean norm(prior_bnet_CPD.mean(:) - trained_bnet_CPD.mean(:))];
            euc_diff_cov = [euc_diff_cov norm(prior_bnet_CPD.cov(:) - trained_bnet_CPD.cov(:))];

            % store location of signature
            training_ranges = [training_ranges; range_start:range_end];

        end
    catch err
        1
    end
end
fprintf('\n');

% select N training windows most similar to prior model
divergence_from_prior = (euc_diff_mean/max(euc_diff_mean)).*(euc_diff_cov/max(euc_diff_cov));
[~, idx] = sort(divergence_from_prior);
smallest_idx = idx(1:num_of_windows);
window_lls = lls(smallest_idx);

selected_training_ranges = training_ranges(smallest_idx,:);
selected_training_data = downsampled(selected_training_ranges);

if num_of_windows > 1
    normalised = selected_training_data - repmat(min(selected_training_data,[],2),1,size(selected_training_data,2));
else
    normalised = selected_training_data - min(selected_training_data);
end
flattened_selected_training_data = reshape(normalised.',[],1);
%unique_training_ranges = unique(training_ranges);
fprintf('found %d readings to train on\n', length(flattened_selected_training_data));

end
