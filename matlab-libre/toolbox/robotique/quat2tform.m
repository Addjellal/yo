function T = quat2tform(q)
%QUAT2TFORM Quaternion vers matrice homogène 4x4.
%   T = QUAT2TFORM([W X Y Z]) rend la transformation de rotation pure.
%
%   Une matrice N sur 4 rend un tableau 4x4xN.
%
%   Exemple :
%      quat2tform([1 0 0 0])           % l'identite
%
%   Voir aussi TFORM2QUAT, QUAT2ROTM, ROTM2TFORM.
    T = matlibre_rob_tform(quat2rotm(q));
end
