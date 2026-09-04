function [x, reussi] = matlibre_qp_actif(H, f, A, b, Aeq, beq)
%MATLIBRE_QP_ACTIF Programme quadratique convexe, par contraintes actives.
%   Minimise 0,5*x'Hx + f'x sous A*x <= b et Aeq*x = beq, H étant définie
%   positive.
%
%   La méthode tient en une remarque : à l'optimum, chaque contrainte
%   d'inégalité est soit saturée, soit sans effet. Si l'on savait
%   lesquelles sont saturées, il ne resterait qu'un problème à
%   contraintes d'égalité, que les conditions de Lagrange résolvent d'un
%   seul système linéaire. On devine donc cet ensemble, on résout, et
%   l'on corrige : une contrainte violée y entre, une contrainte dont le
%   multiplicateur est négatif en sort. Le nombre d'ensembles étant fini
%   et le critère décroissant, le procédé s'arrête.
%
%   REUSSI vaut faux quand le système devient singulier : l'appelant
%   revient alors à une méthode moins exigeante.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    f = f(:);
    n = numel(f);
    if isempty(A), A = zeros(0, n); b = zeros(0, 1); end
    if isempty(Aeq), Aeq = zeros(0, n); beq = zeros(0, 1); end
    b = b(:);
    beq = beq(:);
    actives = false(size(A, 1), 1);
    tolerance = 1e-10;
    x = zeros(n, 1);
    reussi = false;
    for iteration = 1:(200 + 20 * size(A, 1))
        indices = find(actives);
        indices = indices(:);
        if isempty(indices)
            E = Aeq;
            e = beq;
        else
            E = [Aeq; A(indices, :)];
            e = [beq; reshape(b(indices), [], 1)];
        end
        [x, multiplicateurs, bon] = resoudre(H, f, E, e);
        if ~bon
            return
        end
        if ~isempty(b)
            violations = A * x - b;
            if ~isempty(indices)
                violations(indices) = -inf;
            end
            [pire, indice] = max(violations);
            if pire > tolerance * max(1, max(abs(b)))
                actives(indice) = true;
                continue
            end
        end
        % Multiplicateurs des seules inégalités : un multiplicateur
        % négatif signale une contrainte qu'il vaut mieux relâcher.
        nombreEgalites = size(Aeq, 1);
        lambdaInegalites = multiplicateurs((nombreEgalites + 1):end);
        if isempty(lambdaInegalites)
            reussi = true;
            return
        end
        [plusNegatif, rang] = min(lambdaInegalites);
        if plusNegatif < -tolerance
            actives(indices(rang)) = false;
            continue
        end
        reussi = true;
        return
    end
end

function [x, multiplicateurs, bon] = resoudre(H, f, E, e)
%RESOUDRE Programme quadratique à contraintes d'égalité, par Lagrange.
    n = size(H, 1);
    m = size(E, 1);
    if m == 0
        if rcond(H) < 1e-14
            x = zeros(n, 1); multiplicateurs = []; bon = false;
            return
        end
        x = -H \ f;
        multiplicateurs = zeros(0, 1);
        bon = true;
        return
    end
    K = [H, E.'; E, zeros(m)];
    second = [-f; e];
    if rcond(K) < 1e-14
        x = zeros(n, 1); multiplicateurs = zeros(m, 1); bon = false;
        return
    end
    solution = K \ second;
    x = solution(1:n);
    % Le système résout H*x + E'*l = -f, c'est-à-dire H*x + f + E'*l = 0 :
    % pour une contrainte A*x <= b devenue active, l positif signale
    % qu'elle retient vraiment la solution.
    multiplicateurs = solution((n + 1):end);
    bon = true;
end
