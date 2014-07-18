% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function HMMs = generateHMMsFromSnippets(snippets)

    % generate HMMs using snippets

    HMMs = struct;
    numOfSnippets = length(snippets.mean);
    HMMs.mean = cell(numOfSnippets,1);
    HMMs.std = cell(numOfSnippets,1);
    HMMs.transition = cell(numOfSnippets,1);
    snippetsNumOfStates = cellfun('length', snippets.mean) + 1;
    for i = 1:length(snippets.mean)
        numOfStates = snippetsNumOfStates(i);
        HMMs.mean{i} = [cell2mat(snippets.mean(i)); 0];
        HMMs.std{i} = [cell2mat(snippets.std(i))'; 1];
        transition = zeros(numOfStates);
        for state = 1:numOfStates
            if state == numOfStates
               transition(state, state) = 1; 
            else
               duration = cell2mat(snippets.duration(i));          
               transition(state, state) = 1 - 1/duration(state);
               transition(state, mod(state, numOfStates) + 1) = 1/duration(state); 
            end
        end
        HMMs.transition{i} = transition;
    end

end

