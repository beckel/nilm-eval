% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [dates] = getDates(house, maxNumOfDays, missingValuesThresholdSM, missingValuesThresholdPlug, dataset, startDate, endDate, ignore_rounded_sm_period)

    % GETDATES returns the dates of days fulfilling the conditions imposed by the threshold values
    %   missingValuesThresholdSM: controls the number of missing values in the
    %                               smartmeter date; 
    %                             0.1 -> 10% of values can be '-1'
    %   missingValuesThresholdPlug: controls the number of missing values in the
    %                               plug data
    
    appliances = findAppliances(house, dataset);
    house_str = num2str(house, '%02d');
    start_date_num = datenum(startDate, 'yyyy-mm-dd');
    end_date_num = datenum(endDate, 'yyyy-mm-dd');
    dates_strs = datestr(start_date_num:end_date_num, 'yyyy-mm-dd');
    day_idx = 1;
    num_of_days_selected = 0;
    num_days = size(dates_strs, 1);
    idx_of_selected_days = zeros(1,maxNumOfDays);
    while(num_of_days_selected < maxNumOfDays && day_idx <= num_days)
        fprintf('  day %d / %d\n', day_idx, num_days);
        day_is_valid = 1;
        filename_sm = strcat(pwd, '/data/', dataset, '/smartmeter/', house_str, '/', dates_strs(day_idx,:), '.mat');
        if exist(filename_sm, 'file')
            sm_consumption = read_smartmeter_data(dataset, house, dates_strs(day_idx, :), 1 , 'powerallphases');
            num_of_missing_values_in_sm = nnz(sm_consumption == -1);
            if num_of_missing_values_in_sm / length(sm_consumption) > missingValuesThresholdSM
                day_is_valid = 0;
            elseif nnz(mod(sm_consumption, 10)) < 1000
                day_is_valid = 0;
            else
                for appliance = appliances
                    plug_str = getPlugNr(appliance, house, dataset);
                    filename_plug = strcat(pwd, '/data/', dataset, '/plugs/', house_str, '/', plug_str,'/', dates_strs(day_idx,:), '.mat');
                    if exist(filename_plug, 'file')
                        plug_consumption = read_plug_data(dataset, house, appliance, dates_strs(day_idx, :), 1 );
                        num_of_missing_values_in_plug = nnz(plug_consumption == -1);
                        if num_of_missing_values_in_plug / length(plug_consumption) > missingValuesThresholdPlug
                            day_is_valid = 0;
                        end
                    end
                end
            end
        else
            day_is_valid = 0;
        end
        if day_is_valid == 1
            num_of_days_selected = num_of_days_selected + 1;
            idx_of_selected_days(1, num_of_days_selected) = day_idx; 
        end
        day_idx = day_idx + 1;
    end

    idx_of_selected_days = idx_of_selected_days(1,1:num_of_days_selected);
    dates = dates_strs(idx_of_selected_days, :);

end

