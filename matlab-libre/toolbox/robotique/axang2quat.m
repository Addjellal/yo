function q = axang2quat(axang)
%AXANG2QUAT Axe et angle vers quaternion.
%   Q = AXANG2QUAT([X Y Z THETA]) rend [W X Y Z] avec
%
%      w = cos(theta/2),   [x y z] = sin(theta/2) * axe
%
%   La demi-mesure n'est pas un choix : un quaternion agit sur un vecteur
%   par q v q*, donc deux fois, et il faut la moitié de l'angle pour que
%   le compte tombe juste. C'est aussi pourquoi q et -q décrivent la même
%   rotation.
%
%   Une matrice N sur 4 rend une matrice N sur 4 de quaternions.
%
%   Exemple :
%      axang2quat([0 0 1 pi])       % [0 0 0 1] au signe pres
%
%   Voir aussi QUAT2AXANG, AXANG2ROTM, EUL2QUAT.
    [m, ~] = matlibre_rob_lignes(axang, 4, 'AXANG');
    n = size(m, 1);
    q = zeros(n, 4);
    for k = 1:n
        axe = m(k, 1:3);
        longueur = norm(axe);
        if longueur < eps
            q(k, :) = [1 0 0 0];
            continue
        end
        axe = axe / longueur;
        demi = m(k, 4) / 2;
        q(k, :) = [cos(demi), sin(demi) * axe];
    end
end
