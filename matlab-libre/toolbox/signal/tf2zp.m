function [z, p, k] = tf2zp(b, a)
%TF2ZP Fonction de transfert vers zéros, pôles et gain.
%   [Z,P,K] = TF2ZP(B,A). Les coefficients sont donnés par puissances
%   décroissantes ; K est b(1)/a(1).
%
%   Exemple :
%      [z, p, k] = tf2zp([1 -1], [1 -0.5]);   % z = 1, p = 0.5, k = 1
    b = b(:).';
    a = a(:).';
    if isempty(a) || a(1) == 0
        error('signal:tf2zp:BadDenominator', 'The first denominator coefficient must be nonzero.');
    end
    k = b(1) / a(1);
    if k == 0 && any(b ~= 0)
        premier = find(b ~= 0, 1);
        k = b(premier) / a(1);
    end
    z = roots(b);
    p = roots(a);
end
