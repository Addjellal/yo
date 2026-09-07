function mustBeTextScalar(a)
%MUSTBETEXTSCALAR Exige un seul texte.
%   MUSTBETEXTSCALAR(A) accepte une ligne de caractères, une string
%   scalaire ou une cellule d'un seul texte, et refuse un tableau de
%   plusieurs.
%
%   Exemple :
%      mustBeTextScalar('abc');       % passe
%      mustBeTextScalar({'abc'});     % passe
%
%   Voir aussi MUSTBETEXT, MUSTBENONZEROLENGTHTEXT, ISSCALAR.
    unSeul = (ischar(a) && (isrow(a) || isempty(a))) || ...
             (isstring(a) && isscalar(a)) || ...
             (iscellstr(a) && isscalar(a));
    matlibre_valider(unSeul, 'MATLAB:validators:mustBeTextScalar', ...
                     'La valeur doit être un seul texte.');
end
