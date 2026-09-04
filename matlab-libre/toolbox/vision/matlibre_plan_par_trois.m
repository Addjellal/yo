function parametres = matlibre_plan_par_trois(points)
%MATLIBRE_PLAN_PAR_TROIS Plan passant par trois points.
%   Rend [a b c d] avec a²+b²+c² = 1, ou rien si les trois points sont
%   alignés.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    u = points(2, :) - points(1, :);
    v = points(3, :) - points(1, :);
    normale = cross(u, v);
    longueur = norm(normale);
    if longueur < 1e-12
        parametres = [];
        return
    end
    normale = normale / longueur;
    parametres = [normale, -normale * points(1, :).'];
end
