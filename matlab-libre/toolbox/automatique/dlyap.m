function X = dlyap(A, Q)
%DLYAP Équation de Lyapunov discrète.
%   X = DLYAP(A,Q) résout A*X*A' - X + Q = 0. La solution existe et est
%   unique quand aucun produit de deux valeurs propres de A ne vaut 1 —
%   en particulier quand A est stable au sens discret.
%
%   Pour un système stable et Q = B*B', X est le grammien de
%   commandabilité : l'énergie que l'entrée peut mettre dans chaque état.
%
%   Exemples :
%      X = dlyap(0.5, 1);
%      abs(0.25*X - X + 1) < 1e-12          % l'equation est verifiee
%      X                                    % 1.3333
%
%   Voir aussi LYAP, DARE, GRAM.
    n = size(A, 1);
    M = eye(n^2) - kron(conj(A), A);
    x = M \ Q(:);
    X = reshape(x, n, n);
    X = (X + X') / 2;
end
