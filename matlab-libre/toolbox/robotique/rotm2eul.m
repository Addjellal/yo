function eul = rotm2eul(R, sequence)
%ROTM2EUL Matrice de rotation vers angles d'Euler.
%   EUL = ROTM2EUL(R) rend les trois angles, en radians, de la séquence
%   ZYX : ceux tels que R vaut Rz(A) Ry(B) Rx(C).
%
%   EUL = ROTM2EUL(R,SEQUENCE) emploie une autre séquence. Les douze
%   séquences d'EUL2ROTM sont acceptées.
%
%   Un tableau 3x3xN rend une matrice N sur 3, une ligne par rotation.
%
%   Le second angle sort d'un arc-tangente à deux arguments, non d'un
%   arc-sinus : c'est ce qui garde la précision quand il approche le
%   quart de tour, là où le sinus s'aplatit.
%
%   Au quart de tour exactement — le blocage de cardan — les deux autres
%   angles ne sont plus déterminés séparément, seule leur somme l'est.
%   La fonction annule alors le premier et met tout dans le troisième.
%
%   Exemple :
%      rotm2eul(eul2rotm([0.3 0.2 0.1]))       % [0.3 0.2 0.1]
%      rotm2eul(rotz(90))                      % [pi/2 0 0]
%      rotm2eul(eul2rotm([0.3 0.2 0.1], 'ZYZ'), 'ZYZ')
%
%   Voir aussi EUL2ROTM, ROTM2QUAT, TFORM2EUL, ROTM2AXANG.
    if nargin < 2
        sequence = 'ZYX';
    end
    [axes, signe, tiers, propre] = matlibre_rob_sequence(sequence);
    i = axes(1);
    j = axes(2);
    k = axes(3);
    if ndims(R) == 3
        n = size(R, 3);
        pile = R;
        seul = false;
    else
        n = 1;
        pile = R;
        seul = true;
    end
    eul = zeros(n, 3);
    for p = 1:n
        M = pile(:, :, p);
        if propre
            % Séquence propre : le premier axe revient, et c'est le
            % cosinus du deuxième angle qui se lit sur la diagonale.
            sinus = hypot(M(j, i), M(tiers, i));
            b = atan2(sinus, M(i, i));
            if sinus > 1e-9
                a = atan2(M(j, i), -signe * M(tiers, i));
                c = atan2(M(i, j), signe * M(i, tiers));
            else
                a = 0;
                c = atan2(-signe * M(j, tiers), M(j, j));
            end
        else
            % Tait-Bryan : le sinus du deuxième angle se lit au coin, et
            % son cosinus est la norme des deux termes qui l'accompagnent.
            sinus = signe * M(i, k);
            cosinus = hypot(M(k, k), M(j, k));
            b = atan2(sinus, cosinus);
            if cosinus > 1e-9
                a = atan2(-signe * M(j, k), M(k, k));
                c = atan2(-signe * M(i, j), M(i, i));
            else
                a = 0;
                c = atan2(signe * M(j, i), M(j, j));
            end
        end
        eul(p, :) = [a b c];
    end
    if seul
        eul = eul(1, :);
    end
end
