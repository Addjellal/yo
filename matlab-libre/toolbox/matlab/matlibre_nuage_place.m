function [x, y] = matlibre_nuage_place(places, demiLargeur, demiHauteur)
%MATLIBRE_NUAGE_PLACE Trouve une place libre sur une spirale.
%   On part du centre et l'on tourne en s'éloignant, en s'arrêtant au
%   premier endroit où le rectangle du mot ne recouvre aucun de ceux déjà
%   posés. C'est le placement usuel d'un nuage de mots : il met au centre
%   ce qu'on pose en premier, donc ce qui domine.
%
%   Deux rectangles alignés sur les axes se recouvrent si et seulement si
%   leurs projections se recouvrent sur les deux axes : le test est donc
%   immédiat, et c'est ce qui rend la recherche praticable.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [x, y] = matlibre_nuage_place(zeros(0, 4), 0.1, 0.1);
%      x == 0 && y == 0                % le premier va au centre
%
%   Voir aussi WORDCLOUD.
    if isempty(places)
        x = 0;
        y = 0;
        return
    end
    for pas = 0:2000
        angle = 0.5 * pas;
        rayon = 0.012 * pas;
        x = rayon * cos(angle);
        y = rayon * sin(angle) * 0.6;    % un nuage est plus large que haut
        libre = true;
        for k = 1:size(places, 1)
            if abs(x - places(k, 1)) < demiLargeur + places(k, 3) && ...
               abs(y - places(k, 2)) < demiHauteur + places(k, 4)
                libre = false;
                break
            end
        end
        if libre
            return
        end
    end
    % Aucune place trouvee : on pose au bord plutot que de ne rien poser.
    x = 1.1;
    y = 0;
end
