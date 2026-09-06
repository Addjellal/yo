function R = quat2rotm(q)
%QUAT2ROTM Quaternion [w x y z] vers matrice de rotation.
%   R = QUAT2ROTM(Q) rend la matrice 3x3 correspondante. Le quaternion est
%   normalisé au passage : un quaternion non unitaire décrirait une
%   rotation avec changement d'échelle, ce qui n'est pas une rotation.
%
%   Le résultat est orthogonal de déterminant un, à la précision machine.
%
%   Exemple :
%      R = quat2rotm([1 0 0 0]);       % l'identite
%      quat2rotm(rotm2quat(rotz(30))) - rotz(30)    % ~0
%
%   Voir aussi ROTM2QUAT, QUAT2EUL, QUAT2AXANG.
    q = q / norm(q);
    w = q(1); x = q(2); y = q(3); z = q(4);
    R = [1-2*(y^2+z^2), 2*(x*y-w*z),   2*(x*z+w*y);
         2*(x*y+w*z),   1-2*(x^2+z^2), 2*(y*z-w*x);
         2*(x*z-w*y),   2*(y*z+w*x),   1-2*(x^2+y^2)];
end
