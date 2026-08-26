function x = qfuncinv(q)
%QFUNCINV Réciproque de la fonction Q.
%   Q(x) = 0.5*erfc(x/sqrt(2)), donc x = sqrt(2)*erfcinv(2*q).
%
%   Exemple :
%      qfuncinv(0.5)              % 0
%      qfuncinv(qfunc(1.3))       % 1.3
    x = sqrt(2) * erfcinv(2 * q);
end
