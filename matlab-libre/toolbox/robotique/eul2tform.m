function T = eul2tform(eul, sequence)
%EUL2TFORM Angles d'Euler vers matrice homogène 4x4.
%   T = EUL2TFORM([A B C]) rend la transformation de rotation pure
%   correspondant aux trois angles, en radians, dans la séquence ZYX. La
%   translation est nulle.
%
%   T = EUL2TFORM(EUL,SEQUENCE) emploie une autre séquence ; les douze
%   d'EUL2ROTM sont acceptées.
%
%   Une matrice N sur 3 rend un tableau 4x4xN.
%
%   Exemple :
%      T = eul2tform([pi / 2 0 0]);
%      T(1:3, 1:3)                     % la rotation seule
%      eul2tform([0.3 0.2 0.1], 'XYZ')
%
%   Voir aussi TFORM2EUL, EUL2ROTM, EUL2QUAT, ROTM2TFORM.
    if nargin < 2
        sequence = 'ZYX';
    end
    T = matlibre_rob_tform(eul2rotm(eul, sequence));
end
