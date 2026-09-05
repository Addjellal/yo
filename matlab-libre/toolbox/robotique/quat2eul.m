function eul = quat2eul(q)
%QUAT2EUL Quaternion vers angles d'Euler ZYX.
%   EUL = QUAT2EUL([W X Y Z]) rend [Z Y X] en radians.
%
%   Une matrice N sur 4 rend une matrice N sur 3.
%
%   Le passage se fait par la matrice de rotation : les angles d'Euler
%   n'ont pas d'expression plus directe qui évite les cas particuliers,
%   et celui du blocage de cardan — quand l'angle de tangage atteint un
%   quart de tour — se traite au même endroit pour les deux chemins.
%
%   Exemple :
%      quat2eul(eul2quat([0.3 0.2 0.1]))       % [0.3 0.2 0.1]
%
%   Voir aussi EUL2QUAT, QUAT2ROTM, ROTM2EUL.
    [m, unique] = matlibre_rob_lignes(q, 4, 'Q');
    n = size(m, 1);
    eul = zeros(n, 3);
    for k = 1:n
        eul(k, :) = rotm2eul(quat2rotm(m(k, :)));
    end
    if unique
        eul = eul(1, :);
    end
end
