function indMatrix = convertClusterVector(M)
% CONVERTCLUSTERVECTOR
%   Converts between row vector with cluster number and indicator vector
%   matrix

if size(M, 2) > 1
    indMatrix = zeros(size(M, 1), 1);
    for ii = 1:size(M, 2)
        indMatrix(M(:, ii) == 1) = ii;
    end
else
    indMatrix = sparse(1:size(M, 1), M, 1);
end