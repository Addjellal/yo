function R = eul2rotm(eul, sequence)
%EUL2ROTM Angles d'Euler vers matrice de rotation.
%   R = EUL2ROTM([A B C]) interprète les trois angles, en radians, dans
%   la séquence ZYX : la rotation vaut Rz(A) Ry(B) Rx(C).
%
%   R = EUL2ROTM(EUL,SEQUENCE) emploie une autre séquence. Les douze sont
%   acceptées : les six de Tait-Bryan — 'ZYX', 'XYZ', 'YXZ', 'ZXY',
%   'YZX', 'XZY' — et les six d'Euler propres, qui reviennent à leur
%   premier axe — 'ZYZ', 'ZXZ', 'XYX', 'XZX', 'YXY', 'YZY'.
%
%   Une matrice N sur 3 rend un tableau 3x3xN, une rotation par ligne.
%
%   Les rotations s'appliquent dans l'ordre où on les lit, chacune autour
%   des axes déjà tournés par les précédentes. C'est la convention dite
%   intrinsèque, et c'est celle de MATLAB.
%
%   Exemple :
%      eul2rotm([pi/2 0 0])                    % un quart de tour en lacet
%      eul2rotm([0.3 0.2 0.1], 'XYZ')          % autre sequence, autre R
%      size(eul2rotm(rand(5, 3)))              % 3 3 5
%
%   Voir aussi ROTM2EUL, EUL2QUAT, EUL2TFORM, ROTX, ROTY, ROTZ.
    if nargin < 2
        sequence = 'ZYX';
    end
    [axes, ~, ~, ~] = matlibre_rob_sequence(sequence);
    [m, seul] = matlibre_rob_lignes(eul, 3, 'EUL');
    n = size(m, 1);
    R = zeros(3, 3, n);
    for k = 1:n
        R(:, :, k) = matlibre_rob_axe(axes(1), m(k, 1)) * ...
                     matlibre_rob_axe(axes(2), m(k, 2)) * ...
                     matlibre_rob_axe(axes(3), m(k, 3));
    end
    if seul || n == 1
        R = R(:, :, 1);
    end
end
