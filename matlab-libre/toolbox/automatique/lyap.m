function X = lyap(A, Q, C)
%LYAP Équation de Lyapunov continue.
%   X = LYAP(A,Q) résout A*X + X*A' + Q = 0.
%   X = LYAP(A,B,C) résout A*X + X*B + C = 0 (Sylvester).
%
%   La résolution passe par la forme vectorisée : le produit de
%   Kronecker transforme l'équation matricielle en système linéaire.
%
%   Exemple :
%      lyap(-1, 1)   % 0.5
    if nargin < 3
        n = size(A, 1);
        M = kron(eye(n), A) + kron(conj(A), eye(n));
        x = -M \ Q(:);
        X = reshape(x, n, n);
        X = (X + X') / 2;      % la solution est symétrique
    else
        n = size(A, 1);
        m = size(Q, 1);
        M = kron(eye(m), A) + kron(Q.', eye(n));
        x = -M \ C(:);
        X = reshape(x, n, m);
    end
end
