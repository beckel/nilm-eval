% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [data_median_mean_filtered] = medianMean(data, filterLength)

    % first apply median filter and subsequently, apply mean filter

    data_median_mean_filtered = zeros(size(data));
    for i = 1:size(data,1)
        data_median_filtered = medfilt1(data(i, :), filterLength);
        if rem(filterLength,2) == 0   
            m = filterLength/2;
        else
            m = (filterLength-1)/2;
        end
        paddingStart = ones(1,m)*data_median_filtered(1);
        paddingEnd = ones(1,m)*data_median_filtered(end);
        x = [paddingStart, data_median_filtered, paddingEnd];
        data_median_mean_filtered = filter(ones(1,filterLength)./filterLength, 1, x);
        data_median_mean_filtered = data_median_mean_filtered(2*m+1:end);
    end

end

