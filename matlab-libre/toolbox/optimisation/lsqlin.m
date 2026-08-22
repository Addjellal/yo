function [x, residu] = lsqlin(C, d, A, b, Aeq, beq, bas, haut)
%LSQLIN Moindres carrés linéaires avec contraintes de bornes.
%   X = LSQLIN(C,D) minimise ||C*x - d||.
    if nargin < 3, A = []; end
    if nargin < 4, b = []; end
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end
    if nargin < 7, bas = []; end
    if nargin < 8, haut = []; end
    if isempty(A) && isempty(Aeq) && isempty(bas) && isempty(haut)
        x = C \ d(:);
    else
        H = 2 * (C' * C);
        f = -2 * (C' * d(:));
        x = quadprog(H, f, A, b, Aeq, beq, bas, haut);
    end
    residu = norm(C * x - d(:));
end
