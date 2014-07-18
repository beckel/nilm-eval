% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [e_data] = edgeEnhance5(data)

    % enhance edges in data
       
    e_data = data;    
    % find edges that increase the power
    edges = diff(data) > 5;
    edges_end = find(diff(edges) == -1)+1;
    edges_start = find(diff(edges) == 1)+1;
    if length(edges_end) < 2 || length(edges_start) < 2
        return;
    end
    if edges_end(1) < edges_start(1)
        edges_end = edges_end(2:end);
    end
    if edges_end(end) < edges_start(end)
        edges_start = edges_start(1:end-1);
    end 
    edges_pos = [edges_start; edges_end];
    
    % find edges that decrease the power
    edges = diff(data) < -5;
    edges_end = find(diff(edges) == -1)+1;
    edges_start = find(diff(edges) == 1)+1;
    if length(edges_end) < 2 || length(edges_start) < 2
        return;
    end
    if edges_end(1) < edges_start(1)
        edges_end = edges_end(2:end);
    end
    if edges_end(end) < edges_start(end)
        edges_start = edges_start(1:end-1);
    end 
    edges = [edges_pos, [edges_start; edges_end]];
    
    % enhance edges
    for i = 1:size(edges,2)
        e_start = edges(1,i);
        e_end = edges(2,i);
        if e_start + 10 < e_end
            continue;
        end        
        l=floor((e_end - e_start)/2);
        e_data(1,e_start:e_start+l) = data(1,e_start);
        e_data(1,e_end-l:e_end) = data(1,e_end);
    end
    

end

