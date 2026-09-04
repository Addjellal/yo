function [pointsImage, devant] = worldToImage(parametres, rotation, translation, pointsMonde, varargin)
%WORLDTOIMAGE Projette des points du monde sur le plan image.
%   P = WORLDTOIMAGE(PARAMS,R,T,POINTS) rend les coordonnées image des
%   points donnés. POINTS est une matrice à trois colonnes.
%
%   [P,DEVANT] = WORLDTOIMAGE(...) dit lesquels sont devant la caméra :
%   un point derrière se projette aussi, mais au mauvais endroit, et la
%   projection ne le signale pas d'elle-même.
%
%   WORLDTOIMAGE(...,'ApplyDistortion',true) applique la distorsion de
%   l'objectif après la projection.
%
%   Exemple :
%      c = cameraIntrinsics([800 800], [320 240], [480 640]);
%      worldToImage(c, eye(3), [0 0 10], [0 0 0])    % [320 240]
%
%   Voir aussi POINTSTOWORLD, CAMERAMATRIX, UNDISTORTPOINTS, TRIANGULATE.
    appliquerDistorsion = false;
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'applydistortion')
            appliquerDistorsion = logical(varargin{k+1});
        end
        k = k + 2;
    end
    K = matlibre_camera_matrice(parametres);
    R = double(rotation);
    t = double(translation(:)).';
    monde = double(pointsMonde);
    camera = monde * R + repmat(t, size(monde, 1), 1);
    devant = camera(:, 3) > 0;
    normalises = camera(:, 1:2) ./ repmat(camera(:, 3), 1, 2);
    if appliquerDistorsion && isstruct(parametres)
        normalises = matlibre_camera_distordre(normalises, parametres);
    end
    homogenes = [normalises, ones(size(normalises, 1), 1)] * K;
    pointsImage = homogenes(:, 1:2);
end
