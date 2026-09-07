function [b, a] = zp2tf(z, p, k)
%ZP2TF Zéros, pôles et gain vers fonction de transfert.
%   [B,A] = ZP2TF(Z,P,K) rend les coefficients par puissances décroissantes.
%
%   Exemple :
%      [b, a] = zp2tf([], [-1 -2], 1);
%      a                           % 1 3 2 : (s+1)(s+2)
%
%   Voir aussi TF2ZP, ZP2SOS, ZP2SS.
    if nargin < 3, k = 1; end
    b = k * real(poly(z(:)));
    a = real(poly(p(:)));
end
