function T2 = inner2outer(T1)
%INNER2OUTER Échange les niveaux d'une table de tables.
%   T2 = INNER2OUTER(T1), où chaque variable de T1 est elle-même une
%   table, rend une table dont les variables portent les noms
%   intérieurs. T2.a.un vaut alors T1.un.a : la donnée ne bouge pas,
%   seule la façon de la nommer change.
%
%   C'est utile quand on a rangé des mesures par capteur alors qu'on veut
%   les lire par grandeur, ou l'inverse. Appliquée deux fois de suite,
%   l'opération redonne la table de départ lorsque toutes les tables
%   intérieures ont les mêmes variables : c'est ce qui la définit.
%
%   Quand une table intérieure n'a pas l'une des variables, la colonne
%   correspondante ne figure simplement pas dans le résultat : il n'y a
%   rien à y mettre, et inventer une valeur serait pire.
%
%   Exemple :
%      un = table([1; 2], [3; 4], 'VariableNames', {'a', 'b'});
%      deux = table([5; 6], [7; 8], 'VariableNames', {'a', 'b'});
%      T = table(un, deux, 'VariableNames', {'un', 'deux'});
%      S = inner2outer(T);
%      S.Properties.VariableNames         % {'a', 'b'}
%      isequal(S.a.deux, T.deux.a)        % 1 : la donnee est la meme
%
%   Voir aussi TABLE, SPLITVARS, MERGEVARS, ROWS2VARS, STACK.
    if nargin < 1
        error('MATLAB:minrhs', 'INNER2OUTER attend une table.');
    end
    if ~isa(T1, 'table') && ~isa(T1, 'timetable')
        error('MATLAB:inner2outer:InvalidInput', ...
              'INNER2OUTER attend une table ou un tableau chronologique.');
    end
    nomsExterieurs = T1.Properties.VariableNames;
    if isempty(nomsExterieurs)
        T2 = T1;
        return;
    end
    for k = 1:numel(nomsExterieurs)
        if ~isa(T1.(nomsExterieurs{k}), 'table')
            error('MATLAB:inner2outer:NestedTablesRequired', ...
                  ['INNER2OUTER attend que chaque variable soit une table ; ' ...
                   '« %s » est de classe %s.'], ...
                  nomsExterieurs{k}, class(T1.(nomsExterieurs{k})));
        end
    end

    % Les noms intérieurs, dans l'ordre où ils apparaissent : l'ordre des
    % colonnes est une information, et la perdre ferait d'un aller-retour
    % autre chose que l'identité.
    nomsInterieurs = {};
    for k = 1:numel(nomsExterieurs)
        noms = T1.(nomsExterieurs{k}).Properties.VariableNames;
        for j = 1:numel(noms)
            if ~any(strcmp(noms{j}, nomsInterieurs))
                nomsInterieurs{end+1} = noms{j};   %#ok<AGROW>
            end
        end
    end

    colonnes = cell(1, numel(nomsInterieurs));
    for j = 1:numel(nomsInterieurs)
        presents = {};
        donnees = {};
        for k = 1:numel(nomsExterieurs)
            interieure = T1.(nomsExterieurs{k});
            if any(strcmp(nomsInterieurs{j}, interieure.Properties.VariableNames))
                presents{end+1} = nomsExterieurs{k};              %#ok<AGROW>
                donnees{end+1} = interieure.(nomsInterieurs{j});  %#ok<AGROW>
            end
        end
        colonnes{j} = table(donnees{:}, 'VariableNames', presents);
    end
    T2 = table(colonnes{:}, 'VariableNames', nomsInterieurs);
    if ~isempty(T1.Properties.RowNames)
        T2.Properties.RowNames = T1.Properties.RowNames;
    end
end
