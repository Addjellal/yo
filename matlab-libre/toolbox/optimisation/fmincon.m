function [x, valeur] = fmincon(fonction, x0, A, b, Aeq, beq, bas, haut, nonlin)
%FMINCON Minimisation sous contraintes, par pénalisation extérieure.
%   X = FMINCON(F,X0,A,B) minimise F sous A*x <= b.
%   X = FMINCON(F,X0,A,B,AEQ,BEQ,LB,UB,NONLIN) ajoute les égalités, les
%   bornes et les contraintes non linéaires : NONLIN rend [c, ceq], avec
%   c <= 0 et ceq == 0.
%
%   [X,VAL] = FMINCON(...) rend aussi la valeur atteinte.
%
%   La méthode est la pénalisation extérieure : on minimise le critère
%   augmenté du carré des violations, avec un poids qu'on multiplie par
%   quatre à chaque tour. La solution s'approche donc de la frontière
%   par l'extérieur, et une contrainte peut rester violée d'un
%   millième.
%
%   Exemple :
%      % Le point du demi-plan x+y >= 2 le plus proche de l'origine :
%      % c'est (1,1), sur la frontière.
%      f = @(v) v(1)^2 + v(2)^2;
%      x = fmincon(f, [2; 0], [-1 -1], -2);
%      round(x, 2)                    % [1; 1]
%
%   Voir aussi FMINUNC, FMINSEARCH, LINPROG, QUADPROG, CONEPROG,
%   FMINIMAX, OPTIMOPTIONS.
    if nargin < 3, A = []; end
    if nargin < 4, b = []; end
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end
    if nargin < 7, bas = []; end
    if nargin < 8, haut = []; end
    if nargin < 9, nonlin = []; end
    poids = 10;
    x = x0(:);
    for tour = 1:12
        objectif = @(v) fonction(v) + poids * violation(v, A, b, Aeq, beq, bas, haut, nonlin);
        x = fminsearch(objectif, x);
        poids = poids * 4;
    end
    if ~isempty(bas), x = max(x, bas(:)); end
    if ~isempty(haut), x = min(x, haut(:)); end
    valeur = fonction(x);
end

function v = violation(x, A, b, Aeq, beq, bas, haut, nonlin)
    x = x(:);
    v = 0;
    if ~isempty(A)
        v = v + sum(max(A * x - b(:), 0) .^ 2);
    end
    if ~isempty(Aeq)
        v = v + sum((Aeq * x - beq(:)) .^ 2);
    end
    if ~isempty(bas)
        v = v + sum(max(bas(:) - x, 0) .^ 2);
    end
    if ~isempty(haut)
        v = v + sum(max(x - haut(:), 0) .^ 2);
    end
    if ~isempty(nonlin)
        [c, ceq] = nonlin(x);
        if ~isempty(c)
            v = v + sum(max(c(:), 0) .^ 2);
        end
        if ~isempty(ceq)
            v = v + sum(ceq(:) .^ 2);
        end
    end
end
