% Solves the proximity problem associated with the 1- or 2-dimensional Total Variation Lp norm.
% Depending on the dimension and norm of choice, a different algorithm is used for the
% optimization.
% Currently only p=1,2 are accepted
% Note p=inf is slow.
%
% Inputs:
%   - y: input of the proximity operator.
%   - lambda: premultiplier of the norm.
%   - p: norm.
%   - [threads]: number of threads (default 1). Used only for 2-D signals.
%
% Outputs:
%   - x: solution of the proximity problem.
%   - info: statistical info of the run algorithm:
%       info.iters: number of iterations run (major iterations for the 2D case)
%       info.stop: value of the stopping criterion.
function [x,info] = prox_TVLp(y,lambda,p,threads)
    % Check inputs
    if nargin < 4, threads=1; end;

    % Choose an algorithm depending on the norm and the dimension of the input
    if isvector(y)
        switch p
            % L1: Projected Newton with Armijo step
            case 1
                [x,in] = solveTV1_PNc(y,lambda);
                info.iters = in(1);
                info.stop = in(2);
            % L2: Hybrid More-Sorensen + Projected Gradient
            case 2
                [x,in] = solveTV2_morec2(y,lambda);
                info.iters = in(1);
                info.stop = in(2);
            otherwise
                fprintf(1,'ERROR (prox_TVLp): unacceptable norm p=%d, returning input.\n',p);
                x = y;
        end
    else if length(size(y)) == 2
        [x,in] = solveTVgen_PDykstrac(y,lambda*[1 1],[1 2],[p p],threads);
        info.iters = in(1);
        info.stop = in(2);
    else
        fprintf(1,'ERROR (prox_TVLp): for (N>2)-dimensional inputs use prox_TVgen function. Returning input.\n');
        x = y;        
    end
end
