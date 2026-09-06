function eul = quat2eul(q, sequence)
%QUAT2EUL Quaternion vers angles d'Euler.
%   EUL = QUAT2EUL([W X Y Z]) rend les trois angles de la séquence ZYX,
%   en radians.
%
%   EUL = QUAT2EUL(Q,SEQUENCE) emploie une autre séquence ; les douze
%   d'EUL2ROTM sont acceptées.
%
%   Une matrice N sur 4 rend une matrice N sur 3.
%
%   Le passage se fait par la matrice de rotation : les angles d'Euler
%   n'ont pas d'expression plus directe qui évite les cas particuliers,
%   et celui du blocage de cardan — quand le deuxième angle atteint un
%   quart de tour — se traite au même endroit pour les deux chemins.
%
%   Exemple :
%      quat2eul(eul2quat([0.3 0.2 0.1]))       % [0.3 0.2 0.1]
%      quat2eul(eul2quat([0.3 0.2 0.1], 'XYZ'), 'XYZ')
%
%   Voir aussi EUL2QUAT, QUAT2ROTM, ROTM2EUL.
    if nargin < 2
        sequence = 'ZYX';
    end
    [m, seul] = matlibre_rob_lignes(q, 4, 'Q');
    n = size(m, 1);
    eul = zeros(n, 3);
    for k = 1:n
        eul(k, :) = rotm2eul(quat2rotm(m(k, :)), sequence);
    end
    if seul
        eul = eul(1, :);
    end
end
