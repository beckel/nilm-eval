% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function snippets = generateSnippetsFromPlevels(plevel)

    % generate snippets using power levels

    snippets = struct;
    snippets.duration = {};
    snippets.mean = {};
    snippets.std = {};
    snippets.start = [];
    snippets.end = [];
    snippetStart = 1;
    while snippetStart < length(plevel.startidx) - 4
        snippetFound = 0;        
        for snippetEnd = snippetStart + 1: snippetStart + 3
           if min(plevel.mean(snippetStart:snippetEnd)) + 10 < plevel.mean(snippetStart)
               break;
           end
           if abs(plevel.mean(snippetStart) - plevel.mean(snippetEnd+1)) < 10
               snippets.mean{end+1} = plevel.mean(snippetStart+1:snippetEnd) - plevel.mean(snippetStart);
               snippets.std{end+1} = plevel.std(snippetStart+1:snippetEnd);
               snippets.duration{end+1} = plevel.duration(snippetStart+1:snippetEnd);
               snippets.start(end+1) = snippetStart+1;
               snippets.end(end+1) = snippetEnd;
               snippetFound = 1;
               snippetStart = snippetEnd + 1; 
               break;
           end
        end
        
        if snippetFound == 0
           snippetStart = snippetStart + 1; 
        end
    end

end

