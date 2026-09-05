function T = axang2tform(axang)
%AXANG2TFORM Axe et angle vers matrice homogène 4x4.
%   T = AXANG2TFORM([X Y Z THETA]) rend la transformation de rotation
%   pure : translation nulle, coin supérieur gauche égal à AXANG2ROTM.
%
%   Une matrice N sur 4 rend un tableau 4x4xN.
%
%   Exemple :
%      T = axang2tform([0 0 1 pi / 2]);
%      T(1:3, 4)                       % [0; 0; 0] : aucune translation
%
%   Voir aussi TFORM2AXANG, AXANG2ROTM, ROTM2TFORM, TRVEC2TFORM.
    T = matlibre_rob_tform(axang2rotm(axang));
end
