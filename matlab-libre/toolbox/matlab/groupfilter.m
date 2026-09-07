function [y, garde] = groupfilter(x, classement, condition)
%GROUPFILTER Ne garde que les groupes qui satisfont une condition.
%   Y = GROUPFILTER(X,G,CONDITION) applique CONDITION à chaque groupe et
%   ne garde que les éléments de ceux pour lesquels elle est vraie.
%   CONDITION est une poignée de fonction recevant les valeurs du groupe.
%   [Y,GARDE] = GROUPFILTER(...) rend en outre le masque des éléments
%   gardés.
%
%   Le filtre porte sur le groupe entier, non sur l'élément : un groupe
%   passe ou ne passe pas, et tous ses éléments avec lui. C'est ce qui la
%   distingue d'une simple indexation logique — écarter les catégories
%   trop peu peuplées, garder celles dont la moyenne dépasse un seuil.
%
%   Exemple :
%      x = [1 2 3 40]';
%      g = {'a'; 'a'; 'b'; 'b'};
%      groupfilter(x, g, @(v) mean(v) > 10)'      % 3 40
%      groupfilter(x, g, @(v) numel(v) >= 2)'     % tous : deux par groupe
%
%   Voir aussi GROUPSUMMARY, GROUPTRANSFORM, FINDGROUPS.
    if iscell(classement) && ~iscellstr(classement)
        groupes = findgroups(classement{:});
    else
        groupes = findgroups(classement);
    end
    groupes = groupes(:);
    valeurs = x(:);
    garde = false(numel(valeurs), 1);
    for k = 1:max([0; groupes(~isnan(groupes))])
        dedans = groupes == k;
        if condition(valeurs(dedans))
            garde(dedans) = true;
        end
    end
    y = valeurs(garde);
    if isrow(x)
        y = y.';
        garde = garde.';
    end
end
