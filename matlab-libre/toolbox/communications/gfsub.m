function c = gfsub(a, b, p, longueur)
%GFSUB Différence dans un corps de Galois.
%   C = GFSUB(A,B) soustrait dans GF(2), où c'est la même chose
%   qu'additionner.
%   C = GFSUB(A,B,P) soustrait dans GF(P), P premier.
%   C = GFSUB(A,B,P,LEN) complète le résultat de zéros jusqu'à LEN.
%
%   Exemple :
%      gfsub([1 1 0 1], [1 0 1])      % [0 1 1 1]
%      gfsub([1 2], [4 4], 5)         % [2 3]
%
%   Voir aussi GFADD, GFMUL, GFDIV, GFCONV.
    if nargin < 3 || isempty(p), p = 2; end
    exigerPremier(p, 'gfsub');
    [a, b] = alignerPolynomes(a, b);
    c = mod(a - b, p);
    if nargin >= 4 && ~isempty(longueur)
        c = completerLongueur(c, longueur);
    end
end
