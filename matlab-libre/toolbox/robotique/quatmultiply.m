function q = quatmultiply(a, b)
%QUATMULTIPLY Produit de deux quaternions [w x y z].
%   Q = QUATMULTIPLY(A,B) compose les deux rotations : le résultat
%   correspond au produit des matrices de rotation, dans le même ordre.
%
%   C'est ce qui fait l'intérêt des quaternions : composer deux rotations
%   coûte seize multiplications au lieu de vingt-sept, et le résultat
%   reste unitaire à la précision machine — là où un produit de matrices
%   dérive lentement de l'orthogonalité et demande une réorthogonalisation.
%
%   Le produit n'est pas commutatif, pas plus que celui des rotations.
%
%   Exemple :
%      q1 = rotm2quat(rotz(30));
%      q2 = rotm2quat(roty(-20));
%      quat2rotm(quatmultiply(q1, q2)) - rotz(30) * roty(-20)   % ~0
%
%   Voir aussi QUATDIVIDE, QUATCONJ, QUATINV, QUAT2ROTM.
    q = [a(1)*b(1) - a(2)*b(2) - a(3)*b(3) - a(4)*b(4), ...
         a(1)*b(2) + a(2)*b(1) + a(3)*b(4) - a(4)*b(3), ...
         a(1)*b(3) - a(2)*b(4) + a(3)*b(1) + a(4)*b(2), ...
         a(1)*b(4) + a(2)*b(3) - a(3)*b(2) + a(4)*b(1)];
end
