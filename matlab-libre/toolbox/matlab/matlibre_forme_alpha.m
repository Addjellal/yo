function k = matlibre_forme_alpha(x, y, seuil)
%MATLIBRE_FORME_ALPHA Contour fermé de la forme alpha d'un nuage.
%   On triangule, on garde les triangles dont le cercle circonscrit tient
%   sous le seuil, puis on suit le bord de ce qui reste : les arêtes qui
%   n'appartiennent qu'à un triangle. Ces arêtes se chaînent en un
%   contour, rendu premier point répété à la fin.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      k = matlibre_forme_alpha([0 1 1 0]', [0 0 1 1]', inf);
%      numel(k)                        % 5 : quatre coins et le retour
%
%   Voir aussi BOUNDARY, ALPHASHAPE, DELAUNAY.
    T = matlibre_triangles_alpha(x, y, seuil);
    if isempty(T)
        k = zeros(0, 1);
        return
    end
    aretes = [T(:, [1 2]); T(:, [2 3]); T(:, [3 1])];
    triees = sort(aretes, 2);
    [~, ~, position] = unique(triees, 'rows');
    compte = accumarray(position(:), 1);
    bord = aretes(compte(position) == 1, :);
    k = matlibre_chainer_aretes(bord);
end
