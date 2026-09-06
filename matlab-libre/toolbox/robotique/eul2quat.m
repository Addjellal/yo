function q = eul2quat(eul, sequence)
%EUL2QUAT Angles d'Euler vers quaternion.
%   Q = EUL2QUAT([A B C]) rend le quaternion [W X Y Z] de la rotation
%   décrite par les trois angles, en radians, dans la séquence ZYX.
%
%   Q = EUL2QUAT(EUL,SEQUENCE) emploie une autre séquence ; les douze
%   d'EUL2ROTM sont acceptées.
%
%   Une matrice N sur 3 rend une matrice N sur 4.
%
%   Exemple :
%      eul2quat([0 0 0])                       % [1 0 0 0]
%      eul2quat([pi/2 0 0])                    % un quart de tour en lacet
%      eul2quat([0.3 0.2 0.1], 'ZYZ')
%
%   Voir aussi QUAT2EUL, EUL2ROTM, QUAT2ROTM, EUL2TFORM.
    if nargin < 2
        sequence = 'ZYX';
    end
    [m, seul] = matlibre_rob_lignes(eul, 3, 'EUL');
    n = size(m, 1);
    q = zeros(n, 4);
    for k = 1:n
        q(k, :) = rotm2quat(eul2rotm(m(k, :), sequence));
    end
    if seul
        q = q(1, :);
    end
end
