function mustBeNonzeroLengthText(a)
%MUSTBENONZEROLENGTHTEXT Exige du texte non vide.
%   MUSTBENONZEROLENGTHTEXT(A) refuse la chaîne vide, qui passe pourtant
%   MUSTBETEXT : une chaîne vide est du texte, elle n'est simplement pas
%   utilisable comme nom, comme motif ou comme clé.
%
%   Exemple :
%      mustBeNonzeroLengthText('abc');    % passe
%      mustBeNonzeroLengthText({'a'});    % passe
%
%   Voir aussi MUSTBETEXT, MUSTBETEXTSCALAR, ISEMPTY.
    mustBeText(a);
    liste = cellstr(a);
    matlibre_valider(~isempty(liste) && all(~cellfun(@isempty, liste)), ...
                     'MATLAB:validators:mustBeNonzeroLengthText', ...
                     'Le texte ne doit pas être vide.');
end
