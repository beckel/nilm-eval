% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

% Returns the plug-level data of the specified (house, appliance)-pair
% granularity = data frequency (in seconds)
% dates_strc = days
function [consumption] = read_plug_data(dataset, house, appliance, dates_strs, granularity)
    
    household = num2str(house, '%02d');
    plug = getPlugNr(appliance, house);        
    consumption = zeros(1, size(dates_strs,1) * (24 * 60 * 60) / granularity);
    offset = 1;
    for day=1:size(dates_strs,1)
        filename_plug = strcat(pwd, '/data/', dataset, '/plugs/', household, '/', plug,'/', dates_strs(day,:), '.mat');
        if exist(filename_plug, 'file')
            vars = whos('-file',filename_plug);
            load(filename_plug);
            eval(['smartmeter_data=' vars.name ';']);
            eval(['clear ' vars.name ';']);
            if (granularity > 1)
                [mat,padded] = vec2mat(smartmeter_data.consumption,granularity);
                assert(padded==0, '%i is not a permissable interval (does not divide into 24h)', granularity);
                consumption(1,offset:offset + (24 * 60 * 60) / granularity -1) = mean(mat, 2);           
            else
                consumption(1,offset:offset + (24 * 60 * 60) / granularity -1) = smartmeter_data.consumption;
            end
        else
            consumption(1,offset:offset + (24 * 60 * 60) / granularity -1) = -1;
        end
        offset = offset + (24 * 60 * 60) / granularity;
    end

end
