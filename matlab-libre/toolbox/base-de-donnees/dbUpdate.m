function t = dbUpdate(t, predicat, colonne, valeur)
%DBUPDATE Met à jour une colonne pour les lignes retenues.
    j = find(strcmp(t.colonnes, colonne), 1);
    for k = 1:numel(t.lignes)
        if predicat(t.lignes{k})
            ligne = t.lignes{k};
            ligne{j} = valeur;
            t.lignes{k} = ligne;
        end
    end
end
