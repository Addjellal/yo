function q = tform2quat(T)
%TFORM2QUAT Matrice homogène vers quaternion.
%   Q = TFORM2QUAT(T) ne lit que la partie rotation.
%
%   Exemple :
%      tform2quat(quat2tform([0.5 0.5 0.5 0.5]))
%
%   Voir aussi QUAT2TFORM, TFORM2ROTM, ROTM2QUAT.
    q = rotm2quat(tform2rotm(T));
end
