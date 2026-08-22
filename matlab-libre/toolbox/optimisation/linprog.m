function [x, valeur, drapeau] = linprog(f, A, b, Aeq, beq, bas, haut, x0)
%LINPROG Programmation linéaire : minimise f'*x sous A*x <= b.
%   [X,VAL] = LINPROG(F,A,B) résout le problème par une méthode de
%   pénalisation intérieure : on minimise f'x - mu*sum(log(b - Ax)) pour
%   une suite décroissante de mu, ce qui converge vers l'optimum du
%   problème contraint.
%
%   Les contraintes d'égalité sont traitées par pénalisation quadratique.
    if nargin < 4, Aeq = []; end
    if nargin < 5, beq = []; end
    if nargin < 6, bas = []; end
    if nargin < 7, haut = []; end
    f = f(:);
    n = numel(f);
    if nargin < 8 || isempty(x0)
        x = zeros(n, 1);
        if ~isempty(A)
            % Point intérieur grossier : on recule depuis l'origine.
            marge = b - A * x;
            if any(marge <= 0)
                x = x - 0.1 * A' * (marge <= 0);
            end
        end
    else
        x = x0(:);
    end
    if ~isempty(bas)
        bas = bas(:);
        x = max(x, bas + 0.01);
    end
    if ~isempty(haut)
        haut = haut(:);
        x = min(x, haut - 0.01);
    end
    mu = 1;
    for tour = 1:30
        objectif = @(v) barriere(v, f, A, b, Aeq, beq, bas, haut, mu);
        x = fminsearch(objectif, x);
        mu = mu * 0.45;
    end
    if ~isempty(bas), x = max(x, bas); end
    if ~isempty(haut), x = min(x, haut); end
    valeur = f' * x;
    drapeau = 1;
end

function v = barriere(x, f, A, b, Aeq, beq, bas, haut, mu)
    x = x(:);
    v = f' * x;
    penalite = 0;
    if ~isempty(A)
        marge = b(:) - A * x;
        for k = 1:numel(marge)
            if marge(k) <= 0
                penalite = penalite + 1e6 * (1 - marge(k));
            else
                penalite = penalite - mu * log(marge(k));
            end
        end
    end
    if ~isempty(Aeq)
        e = Aeq * x - beq(:);
        penalite = penalite + 1e4 * sum(e .^ 2);
    end
    if ~isempty(bas)
        d = x - bas(:);
        for k = 1:numel(d)
            if d(k) <= 0
                penalite = penalite + 1e6 * (1 - d(k));
            else
                penalite = penalite - mu * log(d(k));
            end
        end
    end
    if ~isempty(haut)
        d = haut(:) - x;
        for k = 1:numel(d)
            if d(k) <= 0
                penalite = penalite + 1e6 * (1 - d(k));
            else
                penalite = penalite - mu * log(d(k));
            end
        end
    end
    v = v + penalite;
end
