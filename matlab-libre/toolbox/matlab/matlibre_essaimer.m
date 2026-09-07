function x = matlibre_essaimer(x, y)
%MATLIBRE_ESSAIMER Écarte latéralement les points de même abscisse.
%   Les points partageant une abscisse sont répartis symétriquement autour
%   d'elle, dans l'ordre de leur ordonnée. L'écartement est déterministe :
%   deux appels sur les mêmes données donnent le même dessin, ce qu'un
%   tirage aléatoire ne garantirait pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      xs = matlibre_essaimer([1; 1; 1], [1; 2; 3]);
%      numel(unique(xs))               % 3 : ils ne se recouvrent plus
%
%   Voir aussi SWARMCHART, SCATTER.
    valeurs = unique(x);
    for k = 1:numel(valeurs)
        dedans = find(x == valeurs(k));
        n = numel(dedans);
        if n <= 1
            continue
        end
        [~, ordre] = sort(y(dedans));
        % Une largeur qui croît en racine du nombre de points : au-delà,
        % un groupe nombreux deborderait sur son voisin.
        largeur = 0.3 * min(1, sqrt(n) / 5);
        ecarts = linspace(-largeur, largeur, n);
        x(dedans(ordre)) = valeurs(k) + ecarts(:);
    end
end
