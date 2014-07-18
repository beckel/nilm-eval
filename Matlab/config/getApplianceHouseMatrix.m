% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [appliance_house_matrix] = getApplianceHouseMatrix(dataset)

    % returns a matrix that specifies the plug nr of each (appliance,
    % house)-pair

    if strcmpi(dataset, 'eco')
         appliance_house_matrix = [ %(appliance,house)
             1 4  5 1 5 6;        %fridge
             7 6  2 5 0 0;        %freezer
             0 0  0 8 4 0;        %microwave
             0 2  0 0 0 0;        %dishwasher
             0 0  7 7 6 5;        %entertainment
             4 7  6 0 8 8;        %water kettle
             0 10 0 0 0 0;        %cooker
             3 0  3 2 2 4;        %coffee machine  
             5 0  0 0 0 0;        %washing machine
             2 0  0 0 0 0;        %dryer
             0 8  0 3 0 1;        %lamp   
             8 0  4 0 7 0;        %pc 
             0 9  0 4 0 2;        %laptop
             0 11 0 0 0 0;        %tv
             0 12 0 0 0 0;        %stereo
             0 1  1 6 1 0;        %tablet
             0 0  0 0 0 3];       %router

    elseif strcmpi(dataset, 'redd')
        appliance_house_matrix = [ %(appliance,house)
             1 4  0 1 5 6;        %fridge
             7 6  0 5 0 7;        %freezer
             0 0  0 8 4 0;        %microwave
             0 0  0 0 0 0;        %dishwasher
             0 0  0 7 0 5;        %entertainment
             4 0  0 0 3 8;        %water kettle
             0 0  0 0 0 0;        %cooker
             3 0  0 2 2 4;        %coffee machine  
             5 0  0 0 0 0;        %washing machine
             2 0  0 0 0 0;        %dryer
             0 0  0 3 0 6;        %lamp   
             0 0  0 0 7 0;        %pc 
             0 0  0 0 0 0;        %laptops
             0 0  0 0 0 0;        %entertainment_tv
             0 0  0 0 0 0];       %entertainment_rest
    else
        error('dataset not available');
    end
end

