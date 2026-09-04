function parametres = matlibre_plan_moindres_carres(points)
%MATLIBRE_PLAN_MOINDRES_CARRES Plan le plus proche d'un nuage.
%   La normale est le vecteur propre de plus petite valeur propre de la
%   covariance : la direction dans laquelle le nuage s'étend le moins.
%   C'est la solution des moindres carrés totaux, qui minimise la distance
%   au plan et non l'écart vertical.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    centre = mean(points, 1);
    centres = points - repmat(centre, size(points, 1), 1);
    [vecteurs, valeurs] = eig(centres.' * centres);
    [~, rang] = min(real(diag(valeurs)));
    normale = real(vecteurs(:, rang)).';
    normale = normale / norm(normale);
    parametres = [normale, -normale * centre.'];
end
