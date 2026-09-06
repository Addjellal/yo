function eul = tform2eul(T, sequence)
%TFORM2EUL Matrice homogène vers angles d'Euler.
%   EUL = TFORM2EUL(T) ne lit que la partie rotation, et rend les trois
%   angles de la séquence ZYX.
%
%   EUL = TFORM2EUL(T,SEQUENCE) emploie une autre séquence ; les douze
%   d'EUL2ROTM sont acceptées.
%
%   Exemple :
%      tform2eul(eul2tform([0.3 0.2 0.1]))     % [0.3 0.2 0.1]
%
%   Voir aussi EUL2TFORM, TFORM2ROTM, ROTM2EUL.
    if nargin < 2
        sequence = 'ZYX';
    end
    eul = rotm2eul(tform2rotm(T), sequence);
end
