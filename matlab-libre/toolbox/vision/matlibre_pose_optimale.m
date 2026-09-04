function M = matlibre_pose_optimale(source, cible)
%MATLIBRE_POSE_OPTIMALE Transformation rigide qui superpose deux jeux appariés.
%   C'est le problème de Procuste orthogonal : après avoir centré les deux
%   nuages, la rotation optimale se lit sur la décomposition en valeurs
%   singulières de leur produit croisé. Le déterminant est corrigé pour
%   écarter les réflexions, qui minimiseraient l'écart sans être des
%   rotations.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    centreSource = mean(source, 1);
    centreCible = mean(cible, 1);
    A = (source - repmat(centreSource, size(source, 1), 1)).' * ...
        (cible - repmat(centreCible, size(cible, 1), 1));
    [U, ~, V] = svd(A);
    R = V * U.';
    if det(R) < 0
        V(:, end) = -V(:, end);
        R = V * U.';
    end
    t = centreCible.' - R * centreSource.';
    M = [R, t; 0 0 0 1];
end
