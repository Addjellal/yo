function y = grouptransform(x, classement, methode)
%GROUPTRANSFORM Transforme un tableau groupe par groupe.
%   Y = GROUPTRANSFORM(X,G,METHODE) applique la méthode à chaque groupe et
%   rend un tableau de la taille de X : chaque élément reçoit la valeur
%   calculée sur son groupe. METHODE vaut 'zscore', 'norm', 'center',
%   'meanfill', ou une poignée de fonction rendant autant de valeurs
%   qu'elle en reçoit.
%
%   C'est ce qui la sépare de GROUPSUMMARY : celle-ci réduit chaque groupe
%   à une valeur, celle-là le transforme sans changer sa taille. Centrer
%   par groupe, normaliser par groupe, combler les manquants par la
%   moyenne du groupe : ce sont les trois usages, et ils demandent tous
%   que la sortie garde la forme de l'entrée.
%
%   Exemple :
%      x = [1 3 10 20]';
%      g = {'a'; 'a'; 'b'; 'b'};
%      grouptransform(x, g, 'center')'     % -1 1 -5 5
%      grouptransform(x, g, @(v) v / sum(v))'
%
%   Voir aussi GROUPSUMMARY, GROUPFILTER, FINDGROUPS, SPLITAPPLY.
    if iscell(classement) && ~iscellstr(classement)
        groupes = findgroups(classement{:});
    else
        groupes = findgroups(classement);
    end
    f = matlibre_groupe_fonction(methode);
    groupes = groupes(:);
    forme = size(x);
    x = x(:);
    y = x;
    for k = 1:max([0; groupes(~isnan(groupes))])
        dedans = groupes == k;
        transforme = f(x(dedans));
        if numel(transforme) ~= sum(dedans)
            error('MATLAB:grouptransform:SizeMismatch', ...
                  'La transformation doit rendre autant de valeurs qu''elle en reçoit.');
        end
        y(dedans) = transforme(:);
    end
    y = reshape(y, forme);
end
