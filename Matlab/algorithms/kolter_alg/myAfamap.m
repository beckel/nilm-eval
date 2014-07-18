% This file is part of the following project:
% J. Zico Kolter. Tommi Jaakkola.
% Approximate Inference in Additive Factorial HMMs with Application to Energy Disaggregation.
% In: International Conference on Artificial Intelligence and Statistics (AISTATS). 2012.
% Code provided as supplementary material
% Copyright: J. Zico Kolter, MIT CSAIL, 2014.

% Modified by Romano Cicchetti, ETH Zurich, in the context of the NILM-Eval project

function [X0,Z,G] = myAfamap(Y_bar, mu, duration, P, params)

    T = size(Y_bar,2);
    n = size(Y_bar,1);
    N = length(P);

    % factor covariance matrices
    [U,S,V] = svd(params.Sig); 
    Sig_sqrt = U*sqrt(S)*V';
    Sig_isqrt = inv(Sig_sqrt);

    [U,S,V] = svd(params.dSig); 
    dSig_sqrt = U*sqrt(S)*V';
    dSig_isqrt = inv(dSig_sqrt);

    % form matrices
    C = [];
    F_ = cell(N,1);
    dmu = cell(1,N);
    i_diag = [];
    sum_li = 0;
    for i=1:N,
      ki = size(P{i},1);

      [j,k] = find(P{i});
      for l=1:length(j),
        if (j(l) == k(l)), 
          dmu{i}(:,l) = nan*ones(n,1);
        else
          dmu{i}(:,l) = mu{i}(:,j(l)) - mu{i}(:,k(l));
        end
      end

      j = find(P{i});
      A_{i} = sparse(ones(1,ki));
      B1_{i} = kron(ones(1,ki), speye(ki)); B1_{i} = B1_{i}(:,j);
      B2_{i} = kron(speye(ki), ones(1,ki)); B2_{i} = B2_{i}(:,j);
      c0 = vec(ones(ki,ki) - eye(ki));
      C = [C; c0(j)];
      F_{i} = repmat(-log(P{i}(j))-(log(P{i}(i)))^(duration(i)-1), 1, T-1); % adapted
    end

    A = blkdiag(A_{:});
    B1 = blkdiag(B1_{:});
    B2 = blkdiag(B2_{:});
    mu_bar = cell2mat(mu);
    dmu_bar = cell2mat(dmu);
    F = cell2mat(F_);

    D = 0.5*sqdist(dSig_isqrt * dmu_bar, ...
                   dSig_isqrt * diff(Y_bar,1,2));
    D(isnan(D)) = 0;
    d0 = huber(dSig_isqrt*diff(Y_bar,1,2), params.dlambda);

    % set up optimization
    k_bar = size(A,2);
    p = size(D,1);

    Aeq = [kron(speye(T-1), A*B2) sparse(N*(T-1),T-1);
           kron([sparse(1,T-2) 1], A*B1) sparse(N,T-1);
           (kron([speye(T-2) sparse(T-2,1)], B1) - ...
            kron([sparse(T-2,1) speye(T-2)], B2)) sparse((T-2)*k_bar, T-1);
           kron(speye(T-1), C') speye(T-1)];

    beq = [ones(T*N,1);
           zeros((T-2)*k_bar,1);
           ones(T-1,1)];

    tmp = sparse(T-1,T-1,1,T-1,T-1);
    Dt = speye(T-1);
    H = blkdiag(kron(Dt, B2'*mu_bar'*Sig_isqrt'*Sig_isqrt*mu_bar*B2) + ...
                kron(tmp, B1'*mu_bar'*Sig_isqrt'*Sig_isqrt*mu_bar*B1), ...
                sparse(T-1,T-1));
    H = 0.5*(H + H');

    % optimize with cplex and proxTV
    Z = zeros(size(Y_bar));
    p = size(D,1);

    for i=1:params.max_iter,
      oldZ = Z;
      Y_bar0 = Y_bar - Z;
      f = [-vec(B2' * mu_bar' * Sig_isqrt^2 * duration(1:end-1) .* Y_bar0(:,1:end-1)) - ... % adapted
           [sparse(p*(T-2),1); B1' * mu_bar' * Sig_isqrt^2*duration(end).*Y_bar0(:,end)] ... % adapted
           + vec(F) + vec(D); vec(d0)];
      x0 = cplexqp(H,f,[],[], Aeq, beq, zeros(size(f,1),1),[],[]);
      G = reshape(x0(1:p*(T-1)), p, T-1);
      X = [B2*G B1*G(:,end)];
      Y = mu_bar * X;
      if (params.lambda == Inf), break; end;
      Y_bar0 = Y_bar - Y;
      for i=1:size(Z,1),
        Z(i,:) = solveTV1_PNc(Y_bar0(i,:)', params.lambda)';
      end
      if (norm(Z - oldZ) < 1e-4), break; end
    end


    for i=1:N, ki(i) = size(P{i},1); end;
    X0 = mat2cell(X, ki, size(X,2));

end


function f = huber(Y, lambda)
  f = sum(min(0.5*Y.^2, max(lambda^2/2, lambda*abs(Y) - lambda^2/2)),1);
end
