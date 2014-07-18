% This file is part of the following project:
% Oliver Parson, Siddhartha Ghosh, Mark Weal, Alex Rogers.
% Non-intrusive Load Monitoring using Prior Models of General Appliance Types.
% In: 26th AAAI Conference on Artificial Intelligence. Toronto, Canada. 2012.
% Code available for download: https://sites.google.com/site/oliparson/phd-work/research-files/aaai-2012-code.zip?attredirects=0
% Copyright: Oliver Parson et al., University of Southhampton, 2012.

% Modified by Romano Cicchetti, ETH Zurich, in the context of the NILM-Eval project

function [bnet2, loglik] = learn_params_generic(bnet, observations)

engine = smoother_engine(jtree_2TBN_inf_engine(bnet));
ev(2,:) = num2cell([0 observations]);
[bnet2, LLtrace] = my_learn_params_dbn_em(engine, {ev}, 'max_iter', 10, 'verbose', 0);
loglik = LLtrace(end);

