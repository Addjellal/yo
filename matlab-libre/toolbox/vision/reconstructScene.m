function pointsXYZ = reconstructScene(disparites, matriceReprojection)
%RECONSTRUCTSCENE Reconstruit une scène à partir d'une carte de disparités.
%   P = RECONSTRUCTSCENE(D,Q) rend, pour chaque pixel, ses coordonnées
%   dans l'espace. D est la carte de disparités d'une paire rectifiée, Q
%   la matrice de reprojection 4x4 que rend la rectification.
%
%   La disparité est l'écart horizontal entre les deux vues d'un même
%   point : elle décroît avec la distance, et c'est tout le principe de
%   la stéréovision. Un pixel de disparité nulle ou négative n'a pas été
%   apparié ; sa profondeur vaut l'infini.
%
%   Exemple :
%      Q = [1 0 0 -320; 0 1 0 -240; 0 0 0 800; 0 0 1/0.1 0];
%      P = reconstructScene(disparites, Q);
%
%   Voir aussi DISPARITYBM, DISPARITYSGM, RECTIFYSTEREOIMAGES, TRIANGULATE.
    disparites = double(disparites);
    Q = double(matriceReprojection);
    [lignes, colonnes] = size(disparites);
    [X, Y] = meshgrid(0:(colonnes - 1), 0:(lignes - 1));
    homogenes = [X(:), Y(:), disparites(:), ones(numel(disparites), 1)] * Q.';
    poids = homogenes(:, 4);
    valides = isfinite(disparites(:)) & disparites(:) > 0 & abs(poids) > eps;
    coordonnees = nan(numel(disparites), 3);
    coordonnees(valides, :) = homogenes(valides, 1:3) ./ repmat(poids(valides), 1, 3);
    pointsXYZ = reshape(coordonnees, lignes, colonnes, 3);
end
