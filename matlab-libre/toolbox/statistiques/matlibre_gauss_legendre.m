function [noeuds, poids] = matlibre_gauss_legendre(n)
%MATLIBRE_GAUSS_LEGENDRE Nœuds et poids de la quadrature de Gauss-Legendre.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   [X,W] = MATLIBRE_GAUSS_LEGENDRE(N) rend les N nœuds sur [-1,1] et
%   leurs poids, tels que SUM(W .* F(X)) approche l'intégrale de F sur
%   cet intervalle, exactement pour tout polynôme de degré inférieur à
%   2N.
%
%   Les nœuds sont les racines du polynôme de Legendre P_N, cherchées par
%   la méthode de Newton depuis l'approximation de Tricomi ; le poids
%   vaut 2 / ((1-x^2) P'_N(x)^2).
%
%   Les tables déjà calculées sont gardées d'un appel à l'autre : la
%   plage studentisée demande la même quadrature des milliers de fois,
%   et la recalculer chaque fois coûtait plus que l'intégrale elle-même.
    persistent tailles tables
    if isempty(tailles)
        tailles = [];
        tables = {};
    end
    rang = find(tailles == n, 1);
    if ~isempty(rang)
        noeuds = tables{rang}{1};
        poids = tables{rang}{2};
        return;
    end
    noeuds = zeros(1, n);
    poids = zeros(1, n);
    for i = 1:n
        % Approximation de départ : les racines sont proches des cosinus.
        x = cos(pi * (i - 0.25) / (n + 0.5));
        derivee = 1;
        for iteration = 1:100
            % Récurrence de Bonnet pour P_n et sa dérivée.
            p0 = 1;
            p1 = 0;
            for j = 1:n
                p2 = p1;
                p1 = p0;
                p0 = ((2 * j - 1) * x * p1 - (j - 1) * p2) / j;
            end
            derivee = n * (x * p0 - p1) / (x ^ 2 - 1);
            pas = p0 / derivee;
            x = x - pas;
            if abs(pas) < 1e-15
                break;
            end
        end
        noeuds(i) = x;
        poids(i) = 2 / ((1 - x ^ 2) * derivee ^ 2);
    end
    tailles(end + 1) = n;
    tables{end + 1} = {noeuds, poids};
end
