% This file is part of the following project:
% Oliver Parson, Siddhartha Ghosh, Mark Weal, Alex Rogers.
% Non-intrusive Load Monitoring using Prior Models of General Appliance Types.
% In: 26th AAAI Conference on Artificial Intelligence. Toronto, Canada. 2012.
% Code available for download: https://sites.google.com/site/oliparson/phd-work/research-files/aaai-2012-code.zip?attredirects=0
% Copyright: Oliver Parson et al., University of Southhampton, 2012.

% Modified by Romano Cicchetti, ETH Zurich, in the context of the NILM-Eval project

function [mpe] = my_viterbi_diff(bnet, evidence2, ignore_obs, lik_thres)

observed = ~isemptycell(evidence2);

T = length(evidence2);
mpe = evidence2(1:2,:);
d_states = bnet.node_sizes(bnet.dnodes_slice);
max_prob = zeros(d_states,T);
edges = zeros(d_states,T);

initial = struct(bnet.CPD{1});
emission2 = struct(bnet.CPD{2});
transition = struct(bnet.CPD{3});
emission = struct(bnet.CPD{4});
    
% prob of transitions
trans = transition.CPT;
diffMeans = permute(emission.mean, [2,3,1]);
diffCovs = sqrt(permute(emission.cov, [3,4,1,2]));
absoluteMeans = emission2.mean(:)';
absoluteCovs = emission2.cov(:)';

% max product forward pass
for t=1:T,
    % prob of states at t-1
    if t>1
        chain = max_prob(:,t-1);
    end
    
    % prob of diff emission
    emit = normpdf(evidence2{2,t}, diffMeans, diffCovs);
    
    % prob of absolute emission
    emit2 = normcdf(evidence2{3,t}, absoluteMeans, absoluteCovs);
    emit2 = emit2 / sum(emit2(:));

    % ignore observations of low probability
    if ignore_obs && sum(emit(:)) < lik_thres        
        if t==1
            max_prob(:,t) = log(initial.CPT);
        else
            % product
            product = repmat(chain,[1,d_states]) + log(trans) + log(repmat(emit2,[d_states,1]));
            % max
            [max_prob(:,t), edges(:,t)] = max(product);
        end
    else
        if t==1
            max_prob(:,t) = log(initial.CPT);
        else
            %normalise emission probabilites
            emit = emit / sum(emit(:));
            % product
            product = repmat(chain,[1,d_states]) + log(trans) + log(emit) + log(repmat(emit2,[d_states,1]));
            % max
            [max_prob(:,t), edges(:,t)] = max(product);
        end
    end

    
    %normalise
    max_prob(:,t) = max_prob(:,t) - max(max_prob(:,t));
    
    a = max_prob(:,t);
    max_prob((isinf(a)),t) = min(a(~isinf(a))) - 100;
    
    if any(isinf(max_prob(:,t)))
        1;
    end
    
    % if observed then prob = 1
    if observed(1,t)
        max_prob(:,t) = 0;
        max_prob(evidence2{1,t},t) = 1;
    end
end

% backward pass
[~, mpe{1,T}] = max(max_prob(:,T));
for t=T:-1:2,
    mpe{1,t-1} = edges(mpe{1,t},t);
end
