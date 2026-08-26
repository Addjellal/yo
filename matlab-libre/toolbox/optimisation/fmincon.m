function [x, valeur] = fmincon(fonction, x0, A, b, Aeq, beq, bas, haut, nonlin)
%FMINCON Minimisation sous contraintes, par pénalisation extérieure.
%   X = FMINCON(F,X0,A,B) minimise F sous A*x <= b.
%   Les contraintes non linéaires sont données par une fonction rendant
%   [c, ceq] : c <= 0 et ceq == 0.
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
