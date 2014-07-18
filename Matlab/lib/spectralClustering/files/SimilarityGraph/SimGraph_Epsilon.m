function W = SimGraph_Epsilon(M, epsilon)
% SIMGRAPH_EPSILON Returns epsilon similarity graph
%   Returns adjacency matrix for an epsilon similarity graph
%
%   'M' - A d-by-n matrix containing n d-dimensional data points
%   'epsilon' - Parameter for similarity graph
%
%   Author: Ingo Buerk
%   Year  : 2011/2012
%   Bachelor Thesis

n = size(M, 2);

% Preallocating memory is impossible, since we don't know how
% many non-zero elements the matrix is going to contain
indi = [];
indj = [];
inds = [];

for ii = 1:n
    % Compute i-th column of distance matrix
    dist = distEuclidean(repmat(M(:, ii), 1, n), M);
    
    % Find distances smaller than epsilon (unweighted)
    dist = (dist < epsilon);
    
    % Now save the indices and values for the adjacency matrix
    lastind  = size(indi, 2);
    count    = nnz(dist);
    [~, col] = find(dist);
    
    indi(1, lastind+1:lastind+count) = ii;
    indj(1, lastind+1:lastind+count) = col;
    inds(1, lastind+1:lastind+count) = 1;
end

% Create adjacency matrix for similarity graph
W = sparse(indi, indj, inds, n, n);

clear indi indj inds dist lastind count col v;

end