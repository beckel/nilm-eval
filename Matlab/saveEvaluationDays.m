% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [] = saveEvaluationDays()
    
    % stores the evaluation days of a household in 'input/evalDays/dataset/name/household.mat'
    %
    % PARAMETERS:
    % missingValuesThresholdSM: percentage of missing values(-1) allowed
    %   in the smartmeter data
    % missingValuesThresholdPlug: percentage of missing values (-1) allowed
    %   in the plug data
    %
    
    name = 'all';
    dataset = 'eco';
    houses = [1,2,3,4,5,6];
    maxNumOfDays = 1000;
    startDate = '2012-06-01'; 
    endDate = '2013-01-31';
	
    missingValuesThresholdSM = 1; % 1%
    missingValuesThresholdPlug = 1; % 1%

    for house = houses
        fprintf('Processing house %d\n', house);
        evalDays = getDates(house, maxNumOfDays, missingValuesThresholdSM, missingValuesThresholdPlug, dataset, startDate, endDate);    
        path_to_evalDays = strcat(pwd, '/input/evalDays/', dataset, '/', name);
        if ~exist(path_to_evalDays, 'dir')
            mkdir(path_to_evalDays);
        end
        filename_dates = strcat(path_to_evalDays, '/', num2str(house, '%02d'), '.mat');
        save(filename_dates, 'evalDays');
    end
end

