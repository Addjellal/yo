function t = dbTable(colonnes)
%DBTABLE Crée une table vide dont les colonnes sont nommées.
    t = struct();
    t.colonnes = colonnes;
    t.lignes = {};
end
