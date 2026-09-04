function [ligne, colonne] = matlibre_creux_local(G, ligne, colonne)
%MATLIBRE_CREUX_LOCAL Pixel le moins contrasté du carré de trois.
%   [I,J] = MATLIBRE_CREUX_LOCAL(G,I,J) déplace le point (I,J) vers son
%   voisin de plus faible contraste, dans le voisinage de trois sur trois.
%
%   Exemple :
%      G = [5 0; 5 5];
%      [i, j] = matlibre_creux_local(G, 1, 1);   % 1 2
%
%   Voir aussi SUPERPIXELS, MATLIBRE_CONTRASTE_LOCAL.
    [h, l] = size(G);
    lignes = max(1, ligne - 1):min(h, ligne + 1);
    colonnes = max(1, colonne - 1):min(l, colonne + 1);
    bloc = G(lignes, colonnes);
    [~, indice] = min(bloc(:));
    [i, j] = ind2sub(size(bloc), indice);
    ligne = lignes(i);
    colonne = colonnes(j);
end
