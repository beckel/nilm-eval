% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [data_mean_median_filtered] = meanMedian(data, filterLength)

    % first apply mean filter and subsequently, apply median filter

    data_mean_median_filtered = zeros(size(data));
    for i = 1:size(data,1)
        
        if rem(filterLength,2) == 0   
            m = filterLength/2;
        else
            m = (filterLength-1)/2;
        end
        paddingStart = ones(1,m)*data(i,1);
        paddingEnd = ones(1,m)*data(i,end);
        x = [paddingStart, data(i,:), paddingEnd];
        data_mean_filtered = filter(ones(1,filterLength)./filterLength,1, x);
        data_mean_filtered = data_mean_filtered(2*m+1:end);
        data_mean_median_filtered(i,:) = medfilt1(data_mean_filtered, filterLength);
    end

end

