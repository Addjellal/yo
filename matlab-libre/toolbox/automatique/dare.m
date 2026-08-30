function [X, K, poles] = dare(A, B, Q, R)
%DARE Équation de Riccati algébrique discrète.
%   X = DARE(A,B,Q,R) résout A'XA - X - A'XB(B'XB+R)^{-1}B'XA + Q = 0 et
%   rend la solution stabilisante. C'est l'équation de la commande
%   linéaire quadratique à temps discret.
%
%   [X,K,P] = DARE(...) rend en plus le gain K = (B'XB+R)^{-1}B'XA et les
%   pôles de la boucle fermée.
%
%   Exemples :
%      X = dare(0.5, 1, 1, 1);
%      abs(0.5^2*X - X - 0.5^2*X^2/(X+1) + 1) < 1e-9   % l'equation est verifiee
%      [~, K] = dare(0.5, 1, 1, 1);
%      abs(0.5 - K) < 1                     % la boucle fermee est dans le cercle
%
%   Voir aussi CARE, DLQR, DLYAP, LQR.
    if nargin < 4 || isempty(R), R = eye(size(B, 2)); end
    n = size(A, 1);
    X = [];
    if rcond(A) > 1e-12
        G = B * (R \ B');
        AinvT = inv(A');
        Z = [A + G * AinvT * Q, -G * AinvT; -AinvT * Q, AinvT];
        [V, D] = eig(Z);
        valeurs = diag(D);
        stable = abs(valeurs) < 1;
        if sum(stable) == n
            U = V(:, stable);
            X1 = U(1:n, :);
            X2 = U(n+1:end, :);
            if rcond(X1) > 1e-12
                X = real(X2 / X1);
                X = (X + X') / 2;
            end
        end
    end
    if isempty(X)
        X = Q;
        for iteration = 1:20000
            S = B' * X * B + R;
            Kc = S \ (B' * X * A);
            Xn = A' * X * A - A' * X * B * Kc + Q;
            Xn = (Xn + Xn') / 2;
            if norm(Xn - X, 'fro') < 1e-14 * (1 + norm(Xn, 'fro'))
                X = Xn;
                break
            end
            X = Xn;
        end
    end
    S = B' * X * B + R;
    K = S \ (B' * X * A);
    if nargout > 2
        poles = eig(A - B * K);
    end
end
