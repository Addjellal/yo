function T = matlibre_triangles_alpha(x, y, seuil)
%MATLIBRE_TRIANGLES_ALPHA Triangles de Delaunay assez ramassés pour être gardés.
%   Un triangle est gardé si le rayon de son cercle circonscrit ne dépasse
%   pas le seuil. Un triangle étiré a un grand rayon : c'est exactement
%   celui qui relie deux amas éloignés, et le retirer creuse la forme.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      T = matlibre_triangles_alpha([0 1 1 0]', [0 0 1 1]', inf);
%      size(T, 1)                      % 2 : le carre fait deux triangles
%
%   Voir aussi ALPHASHAPE, BOUNDARY, DELAUNAY.
    T = delaunay(x, y);
    if isempty(T) || isinf(seuil)
        return
    end
    garde = false(size(T, 1), 1);
    for e = 1:size(T, 1)
        garde(e) = matlibre_rayon_circonscrit([x(T(e, :)), y(T(e, :))]) <= seuil * (1 + 1e-9);
    end
    T = T(garde, :);
end
