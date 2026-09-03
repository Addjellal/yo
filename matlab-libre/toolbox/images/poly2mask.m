function BW = poly2mask(x, y, m, n)
%POLY2MASK Masque des points intérieurs à un polygone.
%   BW = POLY2MASK(X,Y,M,N) rend une image binaire de M lignes et N
%   colonnes, vraie aux pixels dont le centre est à l'intérieur du
%   polygone de sommets (X,Y). Le polygone est refermé sur lui-même.
%
%   Le test d'appartenance est celui du nombre de traversées : une
%   demi-droite partant du point coupe un nombre impair de côtés si et
%   seulement si le point est dedans.
%
%   Exemple :
%      BW = poly2mask([2 8 8 2], [2 2 8 8], 10, 10);
%      sum(BW(:))
%
%   Voir aussi ROIPOLY, INPOLYGON, ROIFILT2, ROICOLOR, REGIONPROPS.
    x = double(x(:));
    y = double(y(:));
    m = round(m);
    n = round(n);
    BW = false(m, n);
    if numel(x) < 3
        return;
    end
    % Le centre du pixel (i,j) est en (j, i) dans les coordonnées de
    % l'image : la colonne donne l'abscisse.
    for i = 1:m
        for j = 1:n
            BW(i, j) = dansPolygone(j, i, x, y);
        end
    end
end

function dedans = dansPolygone(px, py, x, y)
% Comptage des traversées : on regarde chaque côté qui enjambe la
% hauteur du point, et l'on compte ceux qui le croisent à sa droite.
    dedans = false;
    n = numel(x);
    j = n;
    for i = 1:n
        if ((y(i) > py) ~= (y(j) > py))
            abscisse = x(i) + (py - y(i)) * (x(j) - x(i)) / (y(j) - y(i));
            if px < abscisse
                dedans = ~dedans;
            end
        end
        j = i;
    end
end
