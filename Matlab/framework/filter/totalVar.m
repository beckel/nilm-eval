% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [data_filtered] = totalVar(data, lratio)

    % total variation denoising 
    
    lmax = tvdiplmax(data);
    [data_filtered, ~, ~] = tvdip(data, lmax*lratio, 1, 1e-3, 100);
    data_filtered = data_filtered';

end

