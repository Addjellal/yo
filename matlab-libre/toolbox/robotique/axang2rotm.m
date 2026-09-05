function R = axang2rotm(axang)
%AXANG2ROTM Axe et angle vers matrice de rotation.
%   R = AXANG2ROTM([X Y Z THETA]) rend la rotation d'angle THETA radians
%   autour de l'axe [X Y Z], par la formule de Rodrigues :
%
%      R = I + sin(theta) K + (1 - cos(theta)) K^2
%
%   où K est la matrice antisymétrique du vecteur unitaire de l'axe.
%
%   Une matrice N sur 4 rend un tableau 3x3xN.
%
%   L'axe est normalisé : sa longueur ne porte aucune information, seule
%   sa direction compte.
%
%   Exemple :
%      R = axang2rotm([0 0 1 pi / 2]);   % quart de tour autour de z
%      R * [1; 0; 0]                     % [0; 1; 0]
%
%   Voir aussi ROTM2AXANG, AXANG2QUAT, AXANG2TFORM, EUL2ROTM.
    [m, unique] = matlibre_rob_lignes(axang, 4, 'AXANG');
    n = size(m, 1);
    R = zeros(3, 3, n);
    for k = 1:n
        axe = m(k, 1:3);
        longueur = norm(axe);
        if longueur < eps
            R(:, :, k) = eye(3);
            continue
        end
        axe = axe / longueur;
        theta = m(k, 4);
        K = [0, -axe(3), axe(2); axe(3), 0, -axe(1); -axe(2), axe(1), 0];
        R(:, :, k) = eye(3) + sin(theta) * K + (1 - cos(theta)) * (K * K);
    end
    if unique
        R = R(:, :, 1);
    end
end
