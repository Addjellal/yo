function X = lyap(A, Q, C)
%LYAP Équation de Lyapunov continue.
%   X = LYAP(A,Q) résout A*X + X*A' + Q = 0. La solution existe et est
%   unique quand aucune somme de deux valeurs propres de A n'est nulle —
%   en particulier quand A est stable.
%
%   X = LYAP(A,B,C) résout l'équation de Sylvester A*X + X*B + C = 0.
%
%   Pour A stable et Q définie positive, X définie positive prouve la
%   stabilité : c'est le théorème de Lyapunov, et la fonction V = x'Xx
%   décroît le long des trajectoires.
%
%   Exemples :
%      X = lyap(-1, 2);
%      abs(-X - X + 2) < 1e-12              % l'equation est verifiee
%      X                                    % 1
%      min(eig(lyap([-1 0; 0 -2], eye(2)))) > 0     % definie positive
%
%   Voir aussi DLYAP, CARE, GRAM, EIG.
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
