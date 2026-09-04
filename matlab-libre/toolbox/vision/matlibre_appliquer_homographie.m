function q = matlibre_appliquer_homographie(H, p)
%MATLIBRE_APPLIQUER_HOMOGRAPHIE Transforme des points par une homographie.
%   Q = MATLIBRE_APPLIQUER_HOMOGRAPHIE(H,P) où P a deux colonnes [x y] et
%   H est une matrice trois par trois agissant sur des colonnes
%   homogènes. Q a deux colonnes, la division par la troisième
%   coordonnée étant faite.
%
%   Exemple :
%      matlibre_appliquer_homographie([2 0 0; 0 2 0; 0 0 1], [1 1])   % 2 2
%
%   Voir aussi ESTIMATEUNCALIBRATEDRECTIFICATION, RECTIFYSTEREOIMAGES.
    p = double(p);
    homogenes = [p(:, 1:2), ones(size(p, 1), 1)].';
    transformes = H * homogenes;
    poids = transformes(3, :);
    poids(abs(poids) < eps) = eps;
    q = [transformes(1, :) ./ poids; transformes(2, :) ./ poids].';
end
