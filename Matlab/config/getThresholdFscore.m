% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [threshold] = getThresholdFscore(appliance, household)

  thresholdMatrix = [15 15 0 15 15 15;        %fridge
                     15 15 0 15 15 15;        %freezer
                     15 15 0 50 50 15;        %microwave
                     15 15 0 15 15 15;        %dishwasher
                     15 15 0 15 15 15;        %entertainment
                     15 15 0 15 15 15;        %water kettle
                     15 15 0 15 15 15;        %cooker
                     15 15 0 15 15 15;        %coffee machine  
                     15 15 0 15 15 15;        %washing machine
                     15 15 0 15 15 15;        %dryer
                     15 15 0 15 15 15;        %lamp   
                     15 15 0 15 15 15;        %pc 
                     15 15 0 15 15 15;        %laptop
                     15 15 0 15 15 15;        %tv
                     15 15 0 15 15 15;        %stereo
                     15 15 0 15 15 15;        %tablet
                     15 15 0 15 15 15;        %router
                     15 15 0 15 15 15];       %illuminated fountain

    threshold = thresholdMatrix(appliance, household);             

end

