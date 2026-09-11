function dedans = matlibre_poly_contenu(C, D)
%MATLIBRE_POLY_CONTENU Le contour C est-il à l'intérieur du contour D ?
%   Les deux contours ne se coupent pas — c'est le cas dans un POLYSHAPE
%   bien formé —, donc il suffit de regarder où tombe un seul sommet de
%   C : s'il est dans D, tous le sont.
%
%   On prend un sommet, non le centre de gravité : le centre d'un contour
%   extérieur tombe volontiers dans le trou qu'il entoure, ce qui ferait
%   croire que le grand est dans le petit. Un sommet, lui, ne ment pas.
%
%   Un sommet posé exactement sur le bord de D ne tranche pas : on passe
%   au suivant.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      petit = [4 4; 6 4; 6 6; 4 6];
%      grand = [0 0; 10 0; 10 10; 0 10];
%      matlibre_poly_contenu(petit, grand)      % 1
%      matlibre_poly_contenu(grand, petit)      % 0
%
%   Voir aussi POLYSHAPE, INPOLYGON, MATLIBRE_POLY_ASSEMBLER.
    dedans = false;
    for k = 1:size(C, 1)
        [estDedans, surLeBord] = inpolygon(C(k, 1), C(k, 2), D(:, 1), D(:, 2));
        if surLeBord
            continue
        end
        dedans = estDedans;
        return
    end
end
