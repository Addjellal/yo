function mustBeMember(a, ensemble)
%MUSTBEMEMBER Exige une valeur prise dans un ensemble.
%   MUSTBEMEMBER(A,ENSEMBLE) lève une erreur si un élément de A n'est pas
%   dans ENSEMBLE. C'est le validateur des paramètres à choix fermé — un
%   nom de méthode, un mode, une unité.
%
%   Le message nomme les valeurs admises : c'est la moitié de son utilité,
%   puisqu'il évite d'aller lire le code pour savoir quoi écrire.
%
%   Exemple :
%      mustBeMember('linear', {'linear', 'cubic'});     % passe
%      mustBeMember([1 2], [1 2 3]);                    % passe
%
%   Voir aussi ISMEMBER, VALIDATESTRING, MUSTBETEXT.
    if ischar(a) || isstring(a) || iscellstr(a)
        dedans = all(ismember(cellstr(a), cellstr(ensemble)));
        liste = strjoin(cellstr(ensemble), ', ');
    else
        dedans = all(ismember(a(:), ensemble(:)));
        liste = strjoin(arrayfun(@(v) num2str(v), ensemble(:)', ...
                                 'UniformOutput', false), ', ');
    end
    matlibre_valider(dedans, 'MATLAB:validators:mustBeMember', ...
                     'La valeur doit être l''une de : %s.', liste);
end
