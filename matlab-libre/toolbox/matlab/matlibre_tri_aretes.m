function A = matlibre_tri_aretes(T)
%MATLIBRE_TRI_ARETES Les faces de chaque élément, une ligne par face.
%   Pour un triangle, la face opposée au sommet J est l'arête formée par
%   les deux autres ; pour un tétraèdre, c'est le triangle des trois
%   autres. Les faces sont rangées élément par élément, dans l'ordre des
%   sommets opposés — ce qui fait correspondre la ligne K de la sortie à
%   la colonne de NEIGHBORS.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      A = matlibre_tri_aretes([1 2 3]);
%      size(A)                         % 3 aretes de 2 sommets
%
%   Voir aussi TRIANGULATION, FREEBOUNDARY.
    T = double(T);
    [n, m] = size(T);
    A = zeros(n * m, m - 1);
    for j = 1:m
        autres = [1:j-1, j+1:m];
        A((j-1)*n + (1:n), :) = T(:, autres);
    end
end
