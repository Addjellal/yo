function t = dbInsert(t, valeurs)
%DBINSERT Ajoute une ligne à la table.
%   T = DBINSERT(T,{...}) ajoute une ligne. Le nombre de valeurs doit
%   correspondre au nombre de colonnes, sans quoi la fonction refuse :
%   c'est le seul contrôle de forme, et il vaut mieux qu'il soit strict —
%   une ligne décalée d'une colonne fausse tout ce qui suit.
%
%   Chaque case garde son type : un nom reste une chaîne, un montant un
%   nombre. La table ne convertit rien.
%
%   Exemple :
%      t = dbTable({'nom', 'service', 'salaire'});
%      t = dbInsert(t, {'Dupont', 'etudes', 45000});
%
%   Voir aussi DBTABLE, DBSELECT, DBDELETE.
    if numel(valeurs) ~= numel(t.colonnes)
        error('database:dbInsert:sizeMismatch', ...
              'Expected %d values, got %d.', numel(t.colonnes), numel(valeurs));
    end
    t.lignes{end+1} = valeurs;
end
