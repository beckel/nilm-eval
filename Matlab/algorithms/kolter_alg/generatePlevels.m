% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function plevel = generatePlevels(edgeThreshold, plevelMinLength, data, true_power)

    % create power levels (periods between edges)

    [rows, cols] = find(abs(diff(data)) > edgeThreshold);
    edges = sparse(rows, cols, ones(length(rows),1), 1, size(data, 2)-1);
    plevel = getPowerLevelsStartAndEndTimes(edges, plevelMinLength);
    plevel.mean = zeros(length(plevel.startidx), 1);
    plevel.duration = zeros(length(plevel.startidx), 1);
    
    for i = 1:length(plevel.startidx)
        [mu, ~] = normfit(data(plevel.startidx(i) : plevel.endidx(i)));
        [~, sigma] = normfit(true_power(plevel.startidx(i) : plevel.endidx(i)));
        plevel.mean(i) = mu;
        plevel.std(i) = sigma;
        plevel.duration(i) = plevel.endidx(i) - plevel.startidx(i);
    end

end

