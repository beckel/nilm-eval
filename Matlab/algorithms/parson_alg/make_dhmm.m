% This file is part of the following project:
% Oliver Parson, Siddhartha Ghosh, Mark Weal, Alex Rogers.
% Non-intrusive Load Monitoring using Prior Models of General Appliance Types.
% In: 26th AAAI Conference on Artificial Intelligence. Toronto, Canada. 2012.
% Code available for download: https://sites.google.com/site/oliparson/phd-work/research-files/aaai-2012-code.zip?attredirects=0
% Copyright: Oliver Parson et al., University of Southhampton, 2012.

% Modified by Romano Cicchetti, ETH Zurich, in the context of the NILM-Eval project

%diff hmm
intra = [0 1; 0 0];
inter = [1 1; 0 0];
hstates = size(init,2); % discrete states
ostates = 1; % continuous
node_sizes = [hstates ostates];
observed_nodes = [2]; % per slice. all others are assumed hidden
discrete_nodes = [1]; % per slice. all others are assumed continuous
eclass1 = [1 2];
eclass2 = [3 4];
bnet = mk_dbn(intra, inter, node_sizes, ...
'discrete', discrete_nodes, 'observed', observed_nodes, ... 
'eclass1', eclass1, 'eclass2', eclass2);

%model params
bnet.CPD{1} = tabular_CPD(bnet, 1, 'CPT', init);
bnet.CPD{2} = gaussian_CPD(bnet, 2, 'mean', state_means, 'cov', state_covs);
%bnet.CPD{2} = gaussian_CPD(bnet, 2, 'mean', zeros(1,hstates), 'cov', ones(1,hstates));
bnet.CPD{3} = tabular_CPD(bnet, 3, 'CPT', trans);
bnet.CPD{4} = gaussian_CPD(bnet, 4, 'mean', emit_mean, 'cov', emit_cov);

end
