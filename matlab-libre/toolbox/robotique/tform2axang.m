function axang = tform2axang(T)
%TFORM2AXANG Matrice homogène vers axe et angle.
%   AXANG = TFORM2AXANG(T) ne lit que la partie rotation ; la translation
%   est ignorée.
%
%   Exemple :
%      tform2axang(axang2tform([0 1 0 0.7]))    % [0 1 0 0.7]
%
%   Voir aussi AXANG2TFORM, TFORM2ROTM, TFORM2QUAT, TFORM2TRVEC.
    axang = rotm2axang(tform2rotm(T));
end
