function normalizedData = normalizeData(Data)
% NORMALIZEDATA Normalized data matrix
%   normalizeData(Data) normalizes the d-by-n matrix Data, so that
%   the minimum value of each dimension and for all data points is 0 and
%   the maximum value respectively is 1.

a = 0;
b = 1;

minData = min(Data, [], 2);
maxData = max(Data, [], 2);

r = (a-b) ./ (minData - maxData);
s = a - r .* minData;

normalizedData = repmat(r, 1, size(Data, 2)) .* Data + repmat(s, 1, size(Data, 2));