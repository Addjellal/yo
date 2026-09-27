function oui = isfimath(x)
%ISFIMATH Vrai pour des règles de calcul à virgule fixe (FIMATH).
%   OUI = ISFIMATH(X) vaut vrai si X est un objet FIMATH.
%
%   Exemple :
%      isfimath(fimath)               % true
%
%   Voir aussi FIMATH, ISFI, ISNUMERICTYPE.
    oui = isa(x, 'embedded.fimath');
end
