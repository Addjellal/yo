function H = swarmchart(varargin)
%SWARMCHART Nuage de points dispersés par catégorie.
%   SWARMCHART(X,Y) dessine les points (X,Y) en écartant latéralement ceux
%   qui partagent la même abscisse, de sorte qu'aucun n'en cache un autre.
%   SWARMCHART(X,Y,TAILLE) et SWARMCHART(X,Y,TAILLE,COULEUR) suivent la
%   syntaxe de SCATTER.
%   SWARMCHART(...,'XJitter',...) et les autres propriétés sont acceptées.
%   H = SWARMCHART(...) rend la poignée.
%
%   Un nuage ordinaire superpose les points de même abscisse : sur des
%   données groupées, on ne voit plus qu'un trait vertical et l'effectif
%   disparaît. L'écartement rend visible la densité — c'est la même
%   information qu'un histogramme, mais sans choisir de largeur de classe.
%
%   L'écart est déterministe, non tiré au hasard : les points d'un même
%   groupe sont répartis symétriquement autour de leur abscisse, ce qui
%   redonne le même dessin d'un appel à l'autre.
%
%   Exemple :
%      figure();
%      x = [ones(1, 20), 2 * ones(1, 20)];
%      swarmchart(x, [randn(1, 20), randn(1, 20) + 3]);
%      close all;
%
%   Voir aussi SCATTER, BOXCHART, HISTOGRAM, PLOT.
    entrees = varargin;
    while numel(entrees) >= 3 && (ischar(entrees{end - 1}) || isstring(entrees{end - 1}))
        entrees = entrees(1:end - 2);
    end
    if numel(entrees) < 2
        error('MATLAB:swarmchart:Arguments', 'SWARMCHART attend au moins X et Y.');
    end
    x = double(entrees{1}(:));
    y = double(entrees{2}(:));
    x = matlibre_essaimer(x, y);
    reste = entrees(3:end);
    H = scatter(x, y, reste{:});
end
