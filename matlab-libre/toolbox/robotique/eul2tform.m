function T = eul2tform(eul)
%EUL2TFORM Angles d'Euler ZYX vers matrice homogène 4x4.
%   T = EUL2TFORM([Z Y X]) rend la transformation de rotation pure
%   correspondant aux trois angles, en radians.
%
%   Une matrice N sur 3 rend un tableau 4x4xN.
%
%   Exemple :
%      T = eul2tform([pi / 2 0 0]);
%      T(1:3, 1:3)                     % la rotation seule
%
%   Voir aussi TFORM2EUL, EUL2ROTM, EUL2QUAT, ROTM2TFORM.
    T = matlibre_rob_tform(eul2rotm(eul));
end
