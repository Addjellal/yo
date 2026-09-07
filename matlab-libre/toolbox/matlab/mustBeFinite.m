function mustBeFinite(a)
%MUSTBEFINITE Exige des valeurs finies.
%   MUSTBEFINITE(A) lève une erreur si A contient un infini ou un NaN.
%
%   Exemple :
%      mustBeFinite([1 2 3]);         % passe
%      mustBeFinite(0);               % passe
%
%   Voir aussi MUSTBENONNAN, MUSTBEREAL, ISFINITE.
    matlibre_valider(all(isfinite(a(:))), 'MATLAB:validators:mustBeFinite', ...
                     'La valeur doit être finie.');
end
