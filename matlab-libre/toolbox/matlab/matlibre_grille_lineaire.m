function vq = matlibre_grille_lineaire(x, y, v, xq, yq)
%MATLIBRE_GRILLE_LINEAIRE Interpolation linéaire sur une triangulation.
%   VQ = MATLIBRE_GRILLE_LINEAIRE(X,Y,V,XQ,YQ) triangule les points, situe
%   chaque point demandé dans un triangle, et y interpole linéairement par
%   les coordonnées barycentriques.
%
%   Les coordonnées barycentriques d'un point sont les poids qui
%   l'écrivent comme moyenne des trois sommets ; elles sont toutes
%   positives si et seulement si le point est dans le triangle, ce qui
%   sert à la fois à le situer et à l'interpoler.
%
%   Hors de l'enveloppe des données, la valeur est NaN.
%
%   Exemple :
%      [x, y] = meshgrid(0:1, 0:1);
%      matlibre_grille_lineaire(x(:), y(:), x(:), 0.5, 0.5)      % 0.5
%
%   Voir aussi GRIDDATA, DELAUNAY.
    triangles = delaunay(x, y);
    vq = NaN(numel(xq), 1);
    for k = 1:numel(xq)
        for t = 1:size(triangles, 1)
            sommets = triangles(t, :);
            poids = matlibre_barycentriques(x(sommets), y(sommets), xq(k), yq(k));
            if isempty(poids)
                continue
            end
            if all(poids >= -1e-12)
                vq(k) = poids(:).' * v(sommets);
                break
            end
        end
    end
end
