function q = rotm2quat(R)
%ROTM2QUAT Matrice de rotation vers quaternion [w x y z].
%   Q = ROTM2QUAT(R) rend le quaternion unitaire de la rotation R.
%
%   Le calcul se fait en quatre branches selon lequel des quatre termes
%   est le plus grand : extraire w de la trace seule perdrait toute
%   précision près d'un demi-tour, où la trace vaut -1 et où w s'annule.
%   Choisir la branche la plus grande garde la précision partout.
%
%   Un quaternion et son opposé décrivent la même rotation : la fonction
%   rend celui dont la partie scalaire est positive.
%
%   Exemple :
%      q = rotm2quat(rotz(30));
%      norm(q)                         % 1
%      quat2rotm(q) - rotz(30)         % ~0
%
%   Voir aussi QUAT2ROTM, ROTM2EUL, ROTM2AXANG.
    trace_ = R(1,1) + R(2,2) + R(3,3);
    if trace_ > 0
        s = sqrt(trace_ + 1) * 2;
        w = 0.25 * s;
        x = (R(3,2) - R(2,3)) / s;
        y = (R(1,3) - R(3,1)) / s;
        z = (R(2,1) - R(1,2)) / s;
    elseif R(1,1) > R(2,2) && R(1,1) > R(3,3)
        s = sqrt(1 + R(1,1) - R(2,2) - R(3,3)) * 2;
        w = (R(3,2) - R(2,3)) / s;
        x = 0.25 * s;
        y = (R(1,2) + R(2,1)) / s;
        z = (R(1,3) + R(3,1)) / s;
    elseif R(2,2) > R(3,3)
        s = sqrt(1 + R(2,2) - R(1,1) - R(3,3)) * 2;
        w = (R(1,3) - R(3,1)) / s;
        x = (R(1,2) + R(2,1)) / s;
        y = 0.25 * s;
        z = (R(2,3) + R(3,2)) / s;
    else
        s = sqrt(1 + R(3,3) - R(1,1) - R(2,2)) * 2;
        w = (R(2,1) - R(1,2)) / s;
        x = (R(1,3) + R(3,1)) / s;
        y = (R(2,3) + R(3,2)) / s;
        z = 0.25 * s;
    end
    q = [w x y z];
end
