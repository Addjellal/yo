function [corriges, reprojetes] = undistortPoints(points, parametres)
%UNDISTORTPOINTS Corrige la distorsion d'objectif sur des points image.
%   Q = UNDISTORTPOINTS(P,PARAMS) rend les coordonnées qu'auraient les
%   points si l'objectif était parfait.
%
%   Le modèle de distorsion se calcule dans un sens — du point idéal vers
%   le point observé — et ne s'inverse pas en forme fermée. L'inversion se
%   fait donc par itération : on part du point observé, on lui applique la
%   distorsion, on corrige de l'écart, et l'on recommence. Quelques tours
%   suffisent, la distorsion étant petite.
%
%   [Q,R] = UNDISTORTPOINTS(...) rend aussi l'erreur de reprojection.
%
%   Exemple :
%      c = cameraIntrinsics([800 800], [320 240], [480 640], ...
%                           'RadialDistortion', [-0.2 0.05]);
%      undistortPoints([100 100], c)
%
%   Voir aussi WORLDTOIMAGE, CAMERAPARAMETERS, CAMERAINTRINSICS.
    K = matlibre_camera_matrice(parametres);
    image = double(points);
    homogenes = [image, ones(size(image, 1), 1)] / K;
    observes = homogenes(:, 1:2) ./ repmat(homogenes(:, 3), 1, 2);
    estimes = observes;
    for iteration = 1:20
        distordus = matlibre_camera_distordre(estimes, parametres);
        estimes = estimes + (observes - distordus);
    end
    resultat = [estimes, ones(size(estimes, 1), 1)] * K;
    corriges = resultat(:, 1:2);
    if nargout > 1
        verification = matlibre_camera_distordre(estimes, parametres);
        retour = [verification, ones(size(verification, 1), 1)] * K;
        reprojetes = sqrt(sum((retour(:, 1:2) - image) .^ 2, 2));
    end
end
