function p = bwperim(bw)
%BWPERIM Contour d'une région binaire.
%   P = BWPERIM(BW) garde les pixels vrais qui touchent au moins un pixel
%   faux dans le voisinage à quatre voisins.
%
%   Exemple :
%      sum(sum(bwperim(true(3))))   % 8 : tout sauf le centre
    bw = logical(bw);
    interieur = bw;
    voisins = padarray(bw, [1 1], 0);
    [m, n] = size(bw);
    haut = voisins(1:m, 2:n+1);
    bas = voisins(3:m+2, 2:n+1);
    gauche = voisins(2:m+1, 1:n);
    droite = voisins(2:m+1, 3:n+2);
    entoure = haut & bas & gauche & droite;
    p = interieur & ~entoure;
end
