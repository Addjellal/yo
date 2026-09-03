function [c, valide] = gfdiv(a, b, p)
%GFDIV Quotient terme à terme dans un corps de Galois.
%   C = GFDIV(A,B,P) divise élément par élément dans GF(P), P premier :
%   chaque terme est multiplié par l'inverse modulaire du diviseur.
%   [C,VALIDE] = GFDIV(...) rend un booléen par terme, faux là où le
%   diviseur est nul ; C y vaut -1, comme dans MATLAB.
%
%   Tout élément non nul d'un corps a un inverse : c'est ce qui
%   distingue un corps d'un anneau, et ce qui rend la division possible.
%
%   Exemple :
%      gfdiv([1 4 2], [3 3 3], 5)     % [2 3 4]
%      gfdiv(1, 0, 5)                 % -1 : pas d'inverse de zéro
%
%   Voir aussi GFMUL, GFDECONV, GFADD, GFSUB.
    if nargin < 3 || isempty(p), p = 2; end
    exigerPremier(p, 'gfdiv');
    [a, b] = alignerTermes(a, b);
    a = mod(a, p);
    b = mod(b, p);
    valide = b ~= 0;
    c = -ones(size(b));
    inverses = inverseModulaire(b(valide), p);
    c(valide) = mod(a(valide) .* inverses, p);
end

function v = inverseModulaire(b, p)
%INVERSEMODULAIRE Inverse dans GF(p), par le petit théorème de Fermat.
%   b^(p-1) vaut un, donc b^(p-2) est l'inverse de b.
    v = zeros(size(b));
    for k = 1:numel(b)
        v(k) = puissanceModulaire(b(k), p - 2, p);
    end
end

function r = puissanceModulaire(base, exposant, p)
%PUISSANCEMODULAIRE Exponentiation rapide modulo p.
    r = 1;
    base = mod(base, p);
    while exposant > 0
        if mod(exposant, 2) == 1
            r = mod(r * base, p);
        end
        base = mod(base * base, p);
        exposant = floor(exposant / 2);
    end
end
