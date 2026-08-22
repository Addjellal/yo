function t = dbInsert(t, valeurs)
%DBINSERT Ajoute une ligne à la table.
    if numel(valeurs) ~= numel(t.colonnes)
        error('database:dbInsert:sizeMismatch', ...
              'Expected %d values, got %d.', numel(t.colonnes), numel(valeurs));
    end
    t.lignes{end+1} = valeurs;
end
