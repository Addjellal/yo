function [k, r0] = ac2rc(r)
%AC2RC Coefficients de réflexion d'une suite d'autocorrélation.
%   [K,R0] = AC2RC(R) applique Levinson-Durbin : R(1) est la puissance du
%   signal, K les coefficients de réflexion des ordres successifs.
%
%   Exemple :
%      r = [1 0.5 0.2];
%      [k, r0] = ac2rc(r);
%      all(abs(k) < 1)             % 1 : une autocorrelation valide donne |k| < 1
%
%   Voir aussi RC2AC, AC2POLY, POLY2RC, LEVINSON.
    r = double(r(:));
    r0 = r(1);
    a = ac2poly(r);
    k = poly2rc(a);
end
