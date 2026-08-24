function lignes = epipolarLine(F, points)
%EPIPOLARLINE Droites épipolaires associées à des points.
%   L = EPIPOLARLINE(F,P) rend, pour chaque point de la première image, la
%   droite de la seconde sur laquelle son correspondant doit se trouver.
%   Chaque ligne de L porte [A B C] pour A*x + B*y + C = 0.
%
%   C'est la contrainte épipolaire : connaître F réduit la recherche d'un
%   appariement de deux dimensions à une seule.
%
%   L = EPIPOLARLINE(F',P) rend les droites de la première image
%   correspondant à des points de la seconde.
%
%   Exemple :
%      l = epipolarLine(F, p1);
%      abs(sum(l .* [p2 ones(n,1)], 2))   % nul si p2 correspond à p1
%
%   Voir aussi ESTIMATEFUNDAMENTALMATRIX, TRIANGULATE.
    F = double(F);
    P = double(points);
    n = size(P, 1);
    lignes = ([P, ones(n, 1)] * F')';
    lignes = lignes';
end
