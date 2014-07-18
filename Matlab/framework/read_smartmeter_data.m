% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [result] = read_smartmeter_data(dataset, house, dates_strs, granularity, option)

    % returns the smartmeter data of the specified household
    % granularity = data frequency (in seconds)
    % dates_strc = days
    % option = data type (power, current, ...)
    % adapted from Manuel Klaey

    houseStr = num2str(house, '%02d');
    result = zeros(1, size(dates_strs,1)*(24 * 60 * 60) / granularity);
    offset = 1;
    for day=1:size(dates_strs,1)
        filename_sm = strcat(pwd, '/data/', dataset, '/smartmeter/', houseStr, '/', dates_strs(day,:), '.mat');
        % Smartmeter data
        if exist(filename_sm, 'file')
            vars = whos('-file',filename_sm);
            load(filename_sm);
            eval(['smartmeter_data=' vars.name ';']);
            eval(['clear ' vars.name ';']);
            if (granularity > 1)
                 % powerallphases
                 eval(strcat('[mat,padded] = vec2mat(smartmeter_data.',option, ',', num2str(granularity),');'));
                 assert(padded==0, '%i is not a permissable interval (does not divide into 24h)', granularity);
                 result(1,offset:offset + (24 * 60 * 60)/granularity -1) = mean(mat, 2);            
            else
                 eval(strcat('result(1,offset:offset + (24 * 60 * 60)/granularity -1) = smartmeter_data.',option,';')); 
            end
        else
            result(1,offset:offset + (24 * 60 * 60)/granularity -1) = -1;
        end
        offset = offset + (24 * 60 * 60) / granularity;
    end

end
