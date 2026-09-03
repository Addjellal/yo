function c = gfconv(a, b, p)
%GFCONV Produit de deux polynômes dans un corps de Galois.
%   C = GFCONV(A,B,P) multiplie les polynômes A et B dans GF(P), P
%   premier. Les coefficients sont rangés par puissances croissantes :
%   A(1) est le terme constant.
%   C = GFCONV(A,B) le fait dans GF(2).
%
%   Le produit se calcule comme la convolution ordinaire, puis se réduit
%   modulo P : c'est ce qui distingue le corps fini des réels.
%
%   Exemple :
%      gfconv([1 1], [1 1])           % [1 0 1] : (1+x)^2 = 1+x^2 dans GF(2)
%      gfconv([1 1], [1 1], 3)        % [1 2 1]
%
%   Voir aussi GFDECONV, GFMUL, GFADD, GFTRUNC.
    if nargin < 3 || isempty(p), p = 2; end
    exigerPremier(p, 'gfconv');
    a = double(a(:)).';
    b = double(b(:)).';
    c = mod(conv(a, b), p);
    c = gftrunc(c);
end
