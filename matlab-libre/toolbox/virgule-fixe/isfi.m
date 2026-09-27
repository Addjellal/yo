function oui = isfi(x)
%ISFI Vrai pour un nombre à virgule fixe (FI).
%   OUI = ISFI(X) vaut vrai si X est un objet FI.
%
%   Exemple :
%      isfi(fi(pi))                   % true
%      isfi(pi)                       % false
%
%   Voir aussi FI, ISNUMERICTYPE, ISFIMATH.
    oui = isa(x, 'embedded.fi');
end
