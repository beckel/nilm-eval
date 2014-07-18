% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [threshold] = getThresholdDiffOnOff(applianceID) 

    % returns a threshold that defines whether
    % the specified appliance is in state 'on' or 'off'

    threshold_vector = [15;  %fridge
                        15;  %freezer
                        500; %microwave
                        500; %dishwasher
                        15;
                        500; %water kettle
                        500; %cooker
                        15;
                        500; %washing machine
                        300; %dryer
                        15;
                        15;
                        15
                        15
                        15];

     threshold = threshold_vector(applianceID,1);

end

