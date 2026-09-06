function [modele, inliers] = fitPlaneRansac(points, tolerance, iterations)
%FITPLANERANSAC Droite (2-D) ou plan (3-D) dominant, par RANSAC.
%   [MODELE,INLIERS] = FITPLANERANSAC(POINTS,TOLERANCE,ITERATIONS) cherche
%   la droite — en deux dimensions — ou le plan — en trois — qui rallie le
%   plus de points à moins de TOLERANCE de lui.
%
%   MODELE porte les coefficients de l'équation implicite : [A B C] pour
%   A x + B y + C = 0, ou [A B C D] pour A x + B y + C z + D = 0.
%   INLIERS donne les indices des points retenus.
%
%   Le principe : tirer au hasard le minimum de points qui détermine un
%   modèle — deux pour une droite, trois pour un plan —, compter combien
%   de points s'en approchent, et recommencer. Le meilleur tirage gagne.
%
%   C'est ce qui le rend insensible aux points aberrants, là où les
%   moindres carrés cèdent : une droite ajustée par moindres carrés sur un
%   sol semé de parasites passe entre les deux, alors que RANSAC ignore
%   les parasites au lieu de les moyenner.
%
%   TOLERANCE se choisit d'après le bruit de mesure, non d'après la scène.
%   Trop serrée, aucun modèle ne rallie assez de points ; trop lâche, tout
%   se vaut. ITERATIONS vaut 200 par défaut, ce qui suffit tant que les
%   parasites restent minoritaires.
%
%   Exemple :
%      sol = [(0:0.1:5).', 0.2 * (0:0.1:5).' + 1];
%      nuage = [sol; rand(30, 2) * 5];
%      [modele, inliers] = fitPlaneRansac(nuage, 0.05, 500);
%      -modele(1) / modele(2)          % la pente, 0.2
%
%   Voir aussi ICPREGISTER, VOXELDOWNSAMPLE, POLYFIT.
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
