function X = dlyap(A, Q)
%DLYAP Équation de Lyapunov discrète : A*X*A' - X + Q = 0.
%   Exemple :
%      dlyap(0.5, 1)   % 1/(1-0.25) = 1.3333
    n = size(A, 1);
    M = eye(n^2) - kron(conj(A), A);
    x = M \ Q(:);
    X = reshape(x, n, n);
    X = (X + X') / 2;
end
