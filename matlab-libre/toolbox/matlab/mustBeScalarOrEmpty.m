function mustBeScalarOrEmpty(a)
%MUSTBESCALAROREMPTY Exige un scalaire ou un vide.
%   MUSTBESCALAROREMPTY(A) accepte un seul élément ou aucun, et refuse
%   deux ou davantage.
%
%   C'est le validateur d'un paramètre facultatif : vide veut dire « non
%   fourni », et une seule valeur veut dire « celle-ci ».
%
%   Exemple :
%      mustBeScalarOrEmpty(3);        % passe
%      mustBeScalarOrEmpty([]);       % passe
%
%   Voir aussi MUSTBEVECTOR, MUSTBENONEMPTY, ISSCALAR, ISEMPTY.
    matlibre_valider(isscalar(a) || isempty(a), ...
                     'MATLAB:validators:mustBeScalarOrEmpty', ...
                     'La valeur doit être un scalaire ou un vide.');
end
