function [modele, inliers] = fitPlaneRansac(points, tolerance, iterations)
%FITPLANERANSAC Droite (2-D) ou plan (3-D) dominant, par RANSAC.
    if nargin < 2, tolerance = 0.05; end
    if nargin < 3, iterations = 200; end
    n = size(points, 1);
    d = size(points, 2);
    meilleur = 0;
    modele = [];
    inliers = [];
    for t = 1:iterations
        indices = randperm(n);
        echantillon = points(indices(1:d), :);
        A = [echantillon, ones(d, 1)];
        [~, ~, V] = svd(A);
        candidat = V(:, end);
        distances = abs([points, ones(n, 1)] * candidat) / max(norm(candidat(1:d)), eps);
        courants = find(distances < tolerance);
        if numel(courants) > meilleur
            meilleur = numel(courants);
            modele = candidat;
            inliers = courants;
        end
    end
end
