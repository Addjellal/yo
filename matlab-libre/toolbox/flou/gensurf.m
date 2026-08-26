function [x, y, z] = gensurf(fis, entrees, sortie, points)
%GENSURF Surface de réponse d'un système flou.
%   [X,Y,Z] = GENSURF(FIS) évalue la sortie sur une grille des deux
%   premières entrées. Sans sortie demandée, la surface est tracée.
%
%   Exemple :
%      [x, y, z] = gensurf(fis);
    if nargin < 2 || isempty(entrees), entrees = [1 2]; end
    if nargin < 3 || isempty(sortie), sortie = 1; end
    if nargin < 4 || isempty(points), points = 15; end
    n = numel(fis.input);
    if n < 2
        plage = linspace(fis.input(1).range(1), fis.input(1).range(2), points)';
        z = zeros(points, 1);
        for k = 1:points
            r = evalfis(plage(k), fis);
            z(k) = r(sortie);
        end
        x = plage;
        y = z;
        if nargout == 0
            plot(x, z);
            xlabel(fis.input(1).name);
            ylabel(fis.output(sortie).name);
            clear x y z
        end
        return
    end
    a = linspace(fis.input(entrees(1)).range(1), fis.input(entrees(1)).range(2), points);
    b = linspace(fis.input(entrees(2)).range(1), fis.input(entrees(2)).range(2), points);
    [x, y] = meshgrid(a, b);
    z = zeros(size(x));
    modele = zeros(1, n);
    for j = 1:n
        modele(j) = mean(fis.input(j).range);
    end
    for i = 1:numel(x)
        v = modele;
        v(entrees(1)) = x(i);
        v(entrees(2)) = y(i);
        r = evalfis(v, fis);
        z(i) = r(sortie);
    end
    if nargout == 0
        surf(x, y, z);
        xlabel(fis.input(entrees(1)).name);
        ylabel(fis.input(entrees(2)).name);
        zlabel(fis.output(sortie).name);
        clear x y z
    end
end
