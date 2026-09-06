function T = rotm2tform(R)
%ROTM2TFORM Rotation vers matrice homogène.
%   T = ROTM2TFORM(R) place la rotation dans le coin supérieur gauche
%   d'une matrice 4x4, la translation restant nulle.
%
%   Exemple :
%      rotm2tform(rotz(90))
%      tform2rotm(rotm2tform(rotz(90))) - rotz(90)   % 0
%
%   Voir aussi TFORM2ROTM, TRVEC2TFORM, EUL2TFORM.
    T = eye(4);
    T(1:3, 1:3) = R;
end
