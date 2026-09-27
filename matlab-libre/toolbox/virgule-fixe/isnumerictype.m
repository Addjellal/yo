function oui = isnumerictype(x)
%ISNUMERICTYPE Vrai pour un type à virgule fixe (NUMERICTYPE).
%   OUI = ISNUMERICTYPE(X) vaut vrai si X est un NUMERICTYPE, ou un
%   Simulink.NumericType que rend FIXDT.
%
%   Exemple :
%      isnumerictype(numerictype(1, 16, 8))    % true
%
%   Voir aussi NUMERICTYPE, ISFI, ISFIMATH.
    oui = isa(x, 'embedded.numerictype') || isa(x, 'Simulink.NumericType');
end
