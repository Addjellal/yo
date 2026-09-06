function [nombre, taux] = biterr(a, b, bits)
%BITERR Nombre et taux d'erreurs binaires entre deux suites d'entiers.
%   NOMBRE = BITERR(A,B) compte les bits qui diffèrent entre les entiers de
%   A et ceux de B, après les avoir écrits sur un même nombre de bits.
%   [NOMBRE,TAUX] = BITERR(A,B) rend en plus le taux, c'est-à-dire ce
%   nombre divisé par le total des bits comparés.
%   [...] = BITERR(A,B,BITS) impose la largeur d'écriture ; par défaut
%   elle est le minimum qui suffit à représenter la plus grande valeur.
%
%   Le taux d'erreur binaire est la mesure de référence d'une chaîne de
%   transmission, parce qu'il se compare directement à la théorie : pour
%   une modulation à deux états dans un bruit gaussien il vaut
%   Q(sqrt(2*Eb/N0)), et l'écart à cette courbe mesure ce que coûte la
%   mise en oeuvre réelle.
%
%   Il ne se confond pas avec le taux d'erreur symbole de SYMERR : un
%   symbole faux porte au moins un bit faux, souvent un seul si le codage
%   est celui de Gray, et tous s'il ne l'est pas. Le rapport entre les
%   deux taux mesure donc la qualité du codage des symboles en bits.
%
%   Exemple :
%      [n, t] = biterr([0 1 2 3], [0 1 3 3]);
%
%   Voir aussi SYMERR, DE2BI, BERAWGN.
    if nargin < 3
        bits = max(1, ceil(log2(max([a(:); b(:)]) + 1)));
    end
    A = de2bi(a(:), bits);
    B = de2bi(b(:), bits);
    nombre = sum(sum(A ~= B));
    taux = nombre / numel(A);
end
