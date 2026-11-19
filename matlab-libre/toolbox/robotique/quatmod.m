function m = quatmod(q)
%QUATMOD Module de quaternions : racine de la somme des carrés.
%   M = QUATMOD(Q) rend, pour chaque ligne de Q (M x 4), la racine de
%   q0^2 + q1^2 + q2^2 + q3^2, en colonne.
%
%   Exemple :
%      quatmod([1 0 1 0])              % 1.4142
%
%   Voir aussi QUATNORM, QUATNORMALIZE.
    m = sqrt(quatnorm(q));
end
