function [X, K, poles] = dare(A, B, Q, R)
%DARE Équation de Riccati algébrique discrète.
%   X = DARE(A,B,Q,R) résout A'XA - X - A'XB(B'XB+R)^{-1}B'XA + Q = 0.
%   [X,K] = DARE(...) rend le gain K = (B'XB+R)^{-1}B'XA.
%   [X,K,P] = DARE(...) rend en plus les pôles de la boucle fermée.
%
%   La solution stabilisante est lue sur le sous-espace invariant stable
%   de la matrice symplectique
%
%      Z = [ A + B R^{-1} B' A^{-T} Q   -B R^{-1} B' A^{-T}
%           -A^{-T} Q                    A^{-T}            ]
%
%   dont les valeurs propres vont par paires (lambda, 1/lambda) : les n
%   qui sont dans le cercle unité engendrent [X1; X2], et X = X2/X1.
%   Quand A est singulière, cette construction n'existe pas et on retombe
%   sur l'itération de Riccati, qui converge linéairement.
%
%   Exemple :
%      dare(1, 1, 1, 1)   % (1 + sqrt(5)) / 2, le nombre d'or
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
