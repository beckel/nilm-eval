function W = SimGraph_NearestNeighbors(M, k, Type, sigma)
% SIMGRAPH_NEARESTNEIGHBORS Returns kNN similarity graph
%   Returns adjacency matrix for an k-Nearest Neighbors 
%   similarity graph
%
%   'M' - A d-by-n matrix containing n d-dimensional data points
%   'k' - Number of neighbors
%   'Type' - Type if kNN Graph
%      1 - Normal
%      2 - Mutual
%   'sigma' - Parameter for Gaussian similarity function. Set
%      this to 0 for an unweighted graph. Default is 1.
%
%   Author: Ingo Buerk
%   Year  : 2011/2012
%   Bachelor Thesis

if nargin < 3
   ME = MException('InvalidCall:NotEnoughArguments', ...
       'Function called with too few arguments');
   throw(ME);
end

if ~any(Type == (1:2))
   ME = MException('InvalidCall:UnknownType', ...
       'Unknown similarity graph type');
   throw(ME);
end

n = size(M, 2);

% Preallocate memory
indi = zeros(1, k * n);
indj = zeros(1, k * n);
inds = zeros(1, k * n);

for ii = 1:n
    % Compute i-th column of distance matrix
    dist = distEuclidean(repmat(M(:, ii), 1, n), M);
    
    % Sort row by distance
    [s, O] = sort(dist, 'ascend');
    
    % Save indices and value of the k 
    indi(1, (ii-1)*k+1:ii*k) = ii;
    indj(1, (ii-1)*k+1:ii*k) = O(1:k);
    inds(1, (ii-1)*k+1:ii*k) = s(1:k);
end

% Create sparse matrix
W = sparse(indi, indj, inds, n, n);

clear indi indj inds dist s O;

% Construct either normal or mutual graph
if Type == 1
    % Normal
    W = max(W, W');
else
    % Mutual
    W = min(W, W');
end

if nargin < 4 || isempty(sigma)
    sigma = 1;
end

% Unweighted graph
if sigma == 0
    W = (W ~= 0);
    
% Gaussian similarity function
elseif isnumeric(sigma)
    W = spfun(@(W) (simGaussian(W, sigma)), W);
    
else
    ME = MException('InvalidArgument:NotANumber', ...
        'Parameter epsilon is not numeric');
    throw(ME);
end

end