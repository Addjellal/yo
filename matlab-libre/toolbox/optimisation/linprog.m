function [x, valeur, drapeau] = linprog(f, A, b, Aeq, beq, bas, haut, x0)
%LINPROG Programmation linéaire : minimise f'*x sous A*x <= b.
%   [X,VAL] = LINPROG(F,A,B) résout le problème par une méthode de
%   pénalisation intérieure : on minimise f'x - mu*sum(log(b - Ax)) pour
%   une suite décroissante de mu, ce qui converge vers l'optimum du
%   problème contraint.
%
%   [X,VAL] = LINPROG(F,A,B,AEQ,BEQ,LB,UB) ajoute les contraintes
%   d'égalité, traitées par pénalisation quadratique, et les bornes. Une
%   borne infinie est reconnue comme telle : elle ne contraint rien.
%
%   Exemple :
%      % Deux ressources, deux produits : on maximise 1*x + 2*y, donc on
%      % minimise l'opposé.
%      [x, val] = linprog([-1; -2], [1 1; 1 3], [4; 6], [], [], [0; 0], []);
%      x                              % [3; 1]
%      val                            % -5
%
%   Voir aussi QUADPROG, INTLINPROG, CONEPROG, LSQLIN, OPTIMPROBLEM.
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
        fini = isfinite(bas);
        x(fini) = max(x(fini), bas(fini) + 0.01);
    end
    if ~isempty(haut)
        haut = haut(:);
        fini = isfinite(haut);
        x(fini) = min(x(fini), haut(fini) - 0.01);
    end
    mu = 1;
    for tour = 1:30
        objectif = @(v) barriere(v, f, A, b, Aeq, beq, bas, haut, mu);
        x = fminsearch(objectif, x);
        mu = mu * 0.45;
    end
    if ~isempty(bas)
        fini = isfinite(bas);
        x(fini) = max(x(fini), bas(fini));
    end
    if ~isempty(haut)
        fini = isfinite(haut);
        x(fini) = min(x(fini), haut(fini));
    end
    % Finition : la barrière approche le sommet sans l'atteindre. Une
    % régularisation quadratique décroissante, résolue exactement par la
    % méthode des contraintes actives, y mène — et l'on ne garde le
    % résultat que s'il respecte les contraintes et améliore le critère.
    [Ac, bc] = matlibre_bornes_en_contraintes(A, b, bas, haut, n);
    [poli, reussi] = matlibre_lp_exact(f, Ac, bc, Aeq, beq);
    if reussi && admissible(poli, Ac, bc, Aeq, beq)
        % Le point de la barrière peut violer légèrement une égalité, ce
        % qui lui donne un critère plus bas que l'optimum vrai : on ne
        % compare les critères que si lui aussi est admissible.
        if ~admissible(x, Ac, bc, Aeq, beq) || f' * poli <= f' * x + 1e-9
            x = poli;
        end
    end
    valeur = f' * x;
    drapeau = 1;
end

function bon = admissible(x, A, b, Aeq, beq)
    bon = true;
    tolerance = 1e-8;
    if ~isempty(A) && any(A * x - b(:) > tolerance * max(1, max(abs(b))))
        bon = false;
    end
    if bon && ~isempty(Aeq) && any(abs(Aeq * x - beq(:)) > tolerance * max(1, max(abs(beq))))
        bon = false;
    end
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
    % Une borne infinie n'en est pas une : son logarithme vaudrait
    % l'infini et emporterait toute la barrière, ce qui figeait la
    % descente au point de départ.
    if ~isempty(bas)
        d = x - bas(:);
        fini = isfinite(bas(:));
        for k = 1:numel(d)
            if ~fini(k)
                continue
            elseif d(k) <= 0
                penalite = penalite + 1e6 * (1 - d(k));
            else
                penalite = penalite - mu * log(d(k));
            end
        end
    end
    if ~isempty(haut)
        d = haut(:) - x;
        fini = isfinite(haut(:));
        for k = 1:numel(d)
            if ~fini(k)
                continue
            elseif d(k) <= 0
                penalite = penalite + 1e6 * (1 - d(k));
            else
                penalite = penalite - mu * log(d(k));
            end
        end
    end
    v = v + penalite;
end
