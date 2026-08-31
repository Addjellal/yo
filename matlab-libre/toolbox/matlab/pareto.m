function [H, indices] = pareto(y, noms, seuil)
%PARETO Diagramme de Pareto : les causes rangées par importance.
%   PARETO(Y) trace les valeurs de Y en barres, de la plus grande à la
%   plus petite, et superpose la courbe de leur somme cumulée en pour
%   cent. C'est le diagramme du contrôle qualité : il montre d'un coup
%   d'œil combien de causes suffisent à expliquer l'essentiel des
%   défauts.
%
%   PARETO(Y,NOMS) étiquette les barres avec les chaînes de NOMS.
%
%   PARETO(Y,NOMS,SEUIL) ne montre que les premières barres, jusqu'à ce
%   que le cumul atteigne SEUIL — une fraction entre 0 et 1. Le défaut
%   est 0.95 : on s'arrête quand 95 pour cent est expliqué.
%
%   [H,I] = PARETO(...) rend les poignées et l'ordre de tri.
%
%   Exemples :
%      pareto([12 3 45 7 22], {'a','b','c','d','e'});
%      % c d'abord, puis e, puis a : trois causes sur cinq
%
%      defauts = [40 25 15 10 5 3 2];
%      pareto(defauts, {}, 0.8);
%
%   Voir aussi BAR, BARH, SORT, CUMSUM, HISTOGRAM.
    if nargin < 2
        noms = {};
    end
    if nargin < 3 || isempty(seuil)
        seuil = 0.95;
    end
    y = y(:);
    [triees, indices] = sort(y, 'descend');
    total = sum(triees);
    if total == 0
        cumul = zeros(size(triees));
    else
        cumul = cumsum(triees) / total;
    end
    garde = numel(triees);
    atteint = find(cumul >= seuil, 1);
    if ~isempty(atteint)
        garde = atteint;
    end
    triees = triees(1:garde);
    cumul = cumul(1:garde);
    indices = indices(1:garde);

    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    H = bar(1:garde, triees);
    hold('on');
    % Le cumul, mis a l'echelle des barres : MatLibre n'a pas de second
    % axe des ordonnees, on ramene donc le pourcentage a la hauteur du
    % plus grand batonnet.
    H(end + 1) = plot(1:garde, cumul * max(triees), 'r-o', 'LineWidth', 1.5);
    if ~aEffacer
        hold('off');
    end
    xticks(1:garde);
    if ~isempty(noms)
        etiquettes = cell(garde, 1);
        for k = 1:garde
            etiquettes{k} = char(noms{indices(k)});
        end
        xticklabels(etiquettes);
    end
    xlim([0.5, garde + 0.5]);
    ylabel('valeur (barres) et cumul (courbe)');
    if nargout == 0
        clear H;
    end
end
