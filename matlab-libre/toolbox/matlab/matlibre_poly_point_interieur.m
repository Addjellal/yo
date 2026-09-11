function p = matlibre_poly_point_interieur(C)
%MATLIBRE_POLY_POINT_INTERIEUR Un point strictement dans un contour.
%   Le barycentre des sommets convient pour un contour convexe, mais pas
%   pour un contour en croissant, où il peut tomber dehors. On l'essaie,
%   et s'il ne va pas, on prend le milieu d'une diagonale qui reste
%   dedans — il en existe toujours une.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      p = matlibre_poly_point_interieur([0 0; 2 0; 2 2; 0 2]);
%      inpolygon(p(1), p(2), [0 2 2 0], [0 0 2 2])
%
%   Voir aussi INPOLYGON, POLYSHAPE.
    p = mean(C, 1);
    if inpolygon(p(1), p(2), C(:, 1), C(:, 2))
        return
    end
    n = size(C, 1);
    for i = 1:n
        for j = i + 2:n
            milieu = (C(i, :) + C(j, :)) / 2;
            if inpolygon(milieu(1), milieu(2), C(:, 1), C(:, 2))
                p = milieu;
                return
            end
        end
    end
end
