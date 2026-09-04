function P = cameraMatrix(parametres, rotation, translation)
%CAMERAMATRIX Matrice de projection d'une caméra posée dans le monde.
%   P = CAMERAMATRIX(PARAMS,R,T) rend la matrice 4x3 qui projette un point
%   du monde, écrit en coordonnées homogènes et en ligne, sur le plan
%   image : [x y w] = [X Y Z 1] * P, et le point image est [x/w y/w].
%
%   La matrice réunit la pose — où est la caméra — et la géométrie
%   interne — comment elle voit. Séparer les deux est ce qui permet
%   d'étalonner une fois et de bouger ensuite.
%
%   Exemple :
%      c = cameraIntrinsics([800 800], [320 240], [480 640]);
%      P = cameraMatrix(c, eye(3), [0 0 10]);
%
%   Voir aussi CAMERAINTRINSICS, WORLDTOIMAGE, TRIANGULATE.
    K = matlibre_camera_matrice(parametres);
    R = double(rotation);
    t = double(translation(:)).';
    P = [R; t] * K;
end
