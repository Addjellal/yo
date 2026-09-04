function [lignes, colonnes] = matlibre_maxima_locaux(carte, seuil)
%MATLIBRE_MAXIMA_LOCAUX Pixels qui dominent leurs huit voisins.
%   [L,C] = MATLIBRE_MAXIMA_LOCAUX(CARTE,SEUIL) rend les pixels dont la
%   valeur dépasse SEUIL et domine ses huit voisins.
%
%   La comparaison est stricte face aux voisins qui précèdent le pixel
%   dans l'ordre de lecture, large face à ceux qui le suivent. Sur un
%   plateau — ce qui arrive dès que le score sature —, un seul pixel est
%   ainsi retenu, le premier ; une comparaison partout large en rendrait
%   tout le plateau.
%
%   Exemple :
%      [l, c] = matlibre_maxima_locaux([0 0 0; 0 1 0; 0 0 0], 0.5);   % 2 2
%      numel(matlibre_maxima_locaux([0 0 0 0; 0 1 1 0; 0 0 0 0], 0.5))  % 1
%
%   Voir aussi DETECTORBFEATURES, DETECTBRISKFEATURES.
    [h, l] = size(carte);
    retenus = carte > seuil;
    retenus([1 h], :) = false;
    retenus(:, [1 l]) = false;
    for di = -1:1
        for dj = -1:1
            if di == 0 && dj == 0
                continue
            end
            decale = -inf(h, l);
            decale(2:end-1, 2:end-1) = carte((2:h-1) + di, (2:l-1) + dj);
            if di < 0 || (di == 0 && dj < 0)
                retenus = retenus & carte > decale;
            else
                retenus = retenus & carte >= decale;
            end
        end
    end
    [lignes, colonnes] = find(retenus);
end
