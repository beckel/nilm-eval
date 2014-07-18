function lambdamax = tvdiplmax(y)
% Calculate the value of lambda so that if lambda >= lambdamax, the TVD
% functional solved by TVDIP is minimized by the trivial constant
% solution x = mean(y). This can then be used to determine a useful range
% of values of lambda, for example.
%
% Usage:
% lambdamax = tvdiplmax(y)
%
% Input arguments:
% - y          Original signal to denoise, size N x 1.
%
% Output arguments:
% - lambdamax  Value of at which x = mean(y) is the output of the TVDIP
%              function.
%
% (c) Max Little, 2010. Based around code originally written by 
% S.J. Kim, K. Koh, S. Boyd and D. Gorinevsky. If you use this code for
% your research, please cite:
% M.A. Little, Nick S. Jones (2010)
% "Sparse Bayesian Step-Filtering for High-Throughput Analysis of Molecular
% Machine Dynamics", in 2010 IEEE International Conference on Acoustics,
% Speech and Signal Processing, 2010, ICASSP 2010 Proceedings.
%
% This code is released under the terms of GNU General Public License as
% published by the Free Software Foundation; version 2 or later.

error(nargchk(1,1,nargin));
y = y(:);
N = length(y);
M = N - 1;

% Construct sparse operator matrices
I1 = speye(M,M);
O1 = spalloc(M,1,M);
D = [I1 O1]-[O1 I1];

DDT = D*D';
Dy  = D*y;

lambdamax = max(abs(DDT\Dy));

