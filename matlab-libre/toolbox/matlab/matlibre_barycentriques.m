function poids = matlibre_barycentriques(xs, ys, x, y)
%MATLIBRE_BARYCENTRIQUES Coordonnées barycentriques dans un triangle.
%   P = MATLIBRE_BARYCENTRIQUES(XS,YS,X,Y) rend les trois poids qui
%   écrivent le point comme moyenne des sommets. Ils somment à un ; ils
%   sont tous positifs exactement quand le point est dans le triangle.
%
%   Un triangle dégénéré — trois sommets alignés — n'en a pas : le
%   résultat est alors vide.
%
%   Exemple :
%      matlibre_barycentriques([0 1 0], [0 0 1], 0.25, 0.25)      % 0.5 0.25 0.25
%
%   Voir aussi MATLIBRE_GRILLE_LINEAIRE, GRIDDATA.
    xs = xs(:);
    ys = ys(:);
    aire = (ys(2) - ys(3)) * (xs(1) - xs(3)) + (xs(3) - xs(2)) * (ys(1) - ys(3));
    if abs(aire) < eps * max(1, max(abs([xs; ys])) ^ 2)
        poids = [];
        return
    end
    premier = ((ys(2) - ys(3)) * (x - xs(3)) + (xs(3) - xs(2)) * (y - ys(3))) / aire;
    deuxieme = ((ys(3) - ys(1)) * (x - xs(3)) + (xs(1) - xs(3)) * (y - ys(3))) / aire;
    poids = [premier, deuxieme, 1 - premier - deuxieme];
end
