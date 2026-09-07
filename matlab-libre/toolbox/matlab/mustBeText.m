function mustBeText(a)
%MUSTBETEXT Exige du texte.
%   MUSTBETEXT(A) accepte un tableau de caractères, un tableau string ou
%   une cellule de textes, et refuse tout le reste.
%
%   Les trois formes du texte en MATLAB se valent ici : c'est justement
%   l'intérêt du validateur, qui laisse l'appelant écrire 'abc', "abc" ou
%   {'abc'} sans que la fonction ait à s'en soucier.
%
%   Exemple :
%      mustBeText('abc');             % passe
%      mustBeText({'a', 'b'});        % passe
%
%   Voir aussi MUSTBETEXTSCALAR, MUSTBEMEMBER, ISCELLSTR, ISSTRING.
    matlibre_valider(ischar(a) || isstring(a) || iscellstr(a), ...
                     'MATLAB:validators:mustBeText', ...
                     'La valeur doit être du texte.');
end
