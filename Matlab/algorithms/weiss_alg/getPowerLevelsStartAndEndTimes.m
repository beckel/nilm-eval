% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [plevel] = getPowerLevelsStartAndEndTimes(edges, plevelMinLength)

    % extract power levels (periods between two edges)
    plevel = struct;
%     plevel_startidx = find(diff(edges) == -1)+1;
%     plevel_endidx = find(diff(edges) == 1)-1;
    plevel_startidx = find(diff(edges) == -1);
    plevel_endidx = find(diff(edges) == 1);
    if length(plevel_startidx) < 2 || length(plevel_endidx) < 2
        plevel.startidx = [];
        plevel.endidx = [];
        return; 
    end
    if plevel_endidx(1) < plevel_startidx(1)
        plevel_endidx = plevel_endidx(2:end);
    end
    if plevel_endidx(end) < plevel_startidx(end)
        plevel_startidx = plevel_startidx(1:end-1);
    end 
    plevels_selected = diff([plevel_startidx; plevel_endidx]) >= plevelMinLength;
    plevel.startidx = plevel_startidx(plevels_selected);
    plevel.endidx = plevel_endidx(plevels_selected);

end

