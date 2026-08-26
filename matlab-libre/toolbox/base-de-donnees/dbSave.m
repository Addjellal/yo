function dbSave(t, nomFichier)
%DBSAVE Écrit la table dans un fichier CSV.
    fid = fopen(nomFichier, 'w');
    for k = 1:numel(t.colonnes)
        if k > 1
            fprintf(fid, ',');
        end
        fprintf(fid, '%s', t.colonnes{k});
    end
    fprintf(fid, '\n');
    for i = 1:numel(t.lignes)
        ligne = t.lignes{i};
        for k = 1:numel(ligne)
            if k > 1
                fprintf(fid, ',');
            end
            v = ligne{k};
            if ischar(v)
                fprintf(fid, '%s', v);
            else
                fprintf(fid, '%g', v);
            end
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
end
