function a = polyarea(x, y, dim)
%POLYAREA Aire d'un polygone.
%   A = POLYAREA(X,Y) rend l'aire du polygone dont les sommets sont
%   (X,Y), pris dans l'ordre. Le contour se referme tout seul : il n'est
%   pas nécessaire de répéter le premier sommet.
%   A = POLYAREA(X,Y,DIM) travaille suivant la dimension DIM ; par défaut
%   la première non singleton, ce qui traite une matrice comme un
%   polygone par colonne.
%
%   La formule est celle du lacet : l'aire vaut la moitié de la somme des
%   produits croisés des sommets consécutifs. Elle se lit comme la somme
%   des aires signées des triangles formés avec l'origine — ceux qui
%   débordent comptent en négatif et se compensent exactement, quelle que
%   soit l'origine choisie et que le polygone soit convexe ou non.
%
%   L'aire rendue est positive : le sens de parcours ne change que le
%   signe, et POLYAREA en prend la valeur absolue.
%
%   Un polygone qui se recoupe n'a pas d'aire bien définie ; la formule en
%   rend une, mais elle compte les régions selon leur enlacement.
%
%   Exemple :
%      polyarea([0 1 1 0], [0 0 1 1])           % 1 : le carre unite
%      polyarea([0 4 4 0], [0 0 3 3])           % 12
%      abs(polyarea(cos(0:0.01:2*pi), sin(0:0.01:2*pi)) - pi) < 1e-3
%
%   Voir aussi INPOLYGON, CONVHULL, BOUNDARY, TRAPZ.
    x = double(x);
    y = double(y);
    if ~isequal(size(x), size(y))
        error('MATLAB:polyarea:tailles', 'X et Y doivent avoir la même taille.');
    end
    if nargin < 3
        if isvector(x)
            x = x(:);
            y = y(:);
        end
        dim = find(size(x) > 1, 1);
        if isempty(dim), dim = 1; end
    end
    suivant = circshift(x, -1, dim) .* y - x .* circshift(y, -1, dim);
    a = abs(sum(suivant, dim)) / 2;
end
