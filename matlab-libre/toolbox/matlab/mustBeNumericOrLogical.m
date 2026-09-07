function mustBeNumericOrLogical(a)
%MUSTBENUMERICORLOGICAL Exige une valeur numérique ou logique.
%   MUSTBENUMERICORLOGICAL(A) accepte ce qu'accepte MUSTBENUMERIC, plus
%   les tableaux logiques.
%
%   La distinction compte : un logique se comporte comme un numérique dans
%   presque tous les calculs, mais pas dans l'indexation, où il désigne des
%   positions au lieu de valoir des rangs.
%
%   Exemple :
%      mustBeNumericOrLogical(true);      % passe
%      mustBeNumericOrLogical(3);         % passe
%
%   Voir aussi MUSTBENUMERIC, MUSTBEREAL, ISLOGICAL.
    matlibre_valider(isnumeric(a) || islogical(a), ...
                     'MATLAB:validators:mustBeNumericOrLogical', ...
                     'La valeur doit être numérique ou logique.');
end
