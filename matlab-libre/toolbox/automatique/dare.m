function [X, K] = dare(A, B, Q, R)
%DARE Équation de Riccati algébrique discrète.
%   X = DARE(A,B,Q,R) résout A'XA - X - A'XB(B'XB+R)^{-1}B'XA + Q = 0.
%   [X,K] = DARE(...) rend le gain K = (B'XB+R)^{-1}B'XA.
%
%   L'itération part de X = Q et applique l'équation jusqu'au point fixe.
    if nargin < 4, R = eye(size(B, 2)); end
    X = Q;
    for iteration = 1:20000
        S = B' * X * B + R;
        K = S \ (B' * X * A);
        Xn = A' * X * A - A' * X * B * K + Q;
        Xn = (Xn + Xn') / 2;
        if norm(Xn - X, 'fro') < 1e-14 * (1 + norm(Xn, 'fro'))
            X = Xn;
            break
        end
        X = Xn;
    end
    S = B' * X * B + R;
    K = S \ (B' * X * A);
end
