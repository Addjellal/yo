function [x, residu] = lsqlin(C, d, A, b, Aeq, beq, bas, haut)
%LSQLIN Moindres carrés linéaires avec contraintes de bornes.
%   X = LSQLIN(C,D) minimise ||C*x - d||.
%   X = LSQLIN(C,D,A,B,AEQ,BEQ,LB,UB) impose A*x <= b, Aeq*x = beq et les
%   bornes. Sans contrainte, la solution est celle de C\D ; les
%   contraintes sont ce qui distingue LSQLIN de l'antislash.
%
%   Exemple :
%      % Le moindres carrés ordinaire, puis le même borné par le haut.
%      C = [1 0; 0 1; 1 1];
%      d = [1; 2; 4];
%      x = lsqlin(C, d);
%      round(x, 3)
%      borne = lsqlin(C, d, [], [], [], [], [], [1; 1]);
%      round(borne, 3)                % chaque terme au plus 1
%
%   Voir aussi LSQNONNEG, LSQNONLIN, LINPROG, QUADPROG, MLDIVIDE.
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
