function c = gfadd(a, b, p, longueur)
%GFADD Somme dans un corps de Galois.
%   C = GFADD(A,B) additionne dans GF(2) : c'est le ou exclusif.
%   C = GFADD(A,B,P) additionne dans GF(P), P premier : chaque terme est
%   la somme modulo P.
%   C = GFADD(A,B,P,LEN) complète le résultat de zéros jusqu'à LEN.
%
%   Employée sur des vecteurs, elle additionne des polynômes écrits par
%   puissances croissantes ; le plus court est complété de zéros.
%
%   Dans un corps de Galois, l'addition est sa propre inverse quand P
%   vaut deux : ajouter deux fois la même chose ne change rien.
%
%   Exemple :
%      gfadd([1 1 0 1], [1 0 1])      % [0 1 1 1] : dans GF(2)
%      gfadd([2 3], [4 4], 5)         % [1 2]
%
%   Voir aussi GFSUB, GFMUL, GFCONV, GFTRUNC.
    if nargin < 3 || isempty(p), p = 2; end
    exigerPremier(p, 'gfadd');
    [a, b] = alignerPolynomes(a, b);
    c = mod(a + b, p);
    if nargin >= 4 && ~isempty(longueur)
        c = completerLongueur(c, longueur);
    end
end
