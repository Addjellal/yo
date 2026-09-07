function [resultat, groupes, identifiants] = groupsummary(x, classement, methode, varargin)
%GROUPSUMMARY Résume un tableau groupe par groupe.
%   R = GROUPSUMMARY(X,G) compte les éléments de chaque groupe défini par
%   G. R = GROUPSUMMARY(X,G,METHODE) applique la méthode nommée à chaque
%   groupe : 'sum', 'mean', 'median', 'min', 'max', 'std', 'var',
%   'numel', 'nnz', 'all', 'any', ou une poignée de fonction.
%   [R,G,ID] = GROUPSUMMARY(...) rend en outre les numéros de groupe et
%   la valeur qui définit chacun.
%
%   G peut être un tableau de classement — les valeurs distinctes forment
%   les groupes — ou une cellule de plusieurs, qui se croisent.
%
%   C'est FINDGROUPS suivi de SPLITAPPLY, réunis en un appel. La
%   différence avec ACCUMARRAY est que les groupes n'ont pas à être des
%   entiers consécutifs : n'importe quelle valeur les définit, texte
%   compris.
%
%   Exemple :
%      x = [1 2 3 4];
%      g = {'a', 'b', 'a', 'b'};
%      groupsummary(x, g, 'sum')'          % 4 6
%      groupsummary(x, g)'                 % 2 2 : les effectifs
%      groupsummary(x, g, @max)'           % 3 4
%
%   Voir aussi FINDGROUPS, SPLITAPPLY, ACCUMARRAY, GROUPTRANSFORM.
    if nargin < 3 || isempty(methode)
        methode = 'numel';
    end
    if iscell(classement) && ~iscellstr(classement)
        [groupes, identifiants] = findgroups(classement{:});
    else
        [groupes, identifiants] = findgroups(classement);
    end
    f = matlibre_groupe_fonction(methode);
    % FINDGROUPS suit la forme de son entree : on rameme tout en colonne.
    groupes = groupes(:);
    valides = ~isnan(groupes);
    nombre = max([0; groupes(valides)]);
    x = x(:);
    premier = f(x(groupes == 1));
    resultat = zeros(nombre, numel(premier));
    resultat(1, :) = premier(:)';
    for k = 2:nombre
        v = f(x(groupes == k));
        resultat(k, :) = v(:)';
    end
    if size(resultat, 2) == 1
        resultat = resultat(:);
    end
end
