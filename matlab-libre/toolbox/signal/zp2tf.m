function [b, a] = zp2tf(z, p, k)
%ZP2TF Zéros, pôles et gain vers fonction de transfert.
%   [B,A] = ZP2TF(Z,P,K) rend les coefficients par puissances décroissantes.
    if nargin < 3, k = 1; end
    b = k * real(poly(z(:)));
    a = real(poly(p(:)));
end
