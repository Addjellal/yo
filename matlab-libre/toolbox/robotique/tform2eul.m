function eul = tform2eul(T)
%TFORM2EUL Matrice homogène vers angles d'Euler ZYX.
%   EUL = TFORM2EUL(T) ne lit que la partie rotation.
%
%   Exemple :
%      tform2eul(eul2tform([0.3 0.2 0.1]))     % [0.3 0.2 0.1]
%
%   Voir aussi EUL2TFORM, TFORM2ROTM, ROTM2EUL.
    eul = rotm2eul(tform2rotm(T));
end
