function dbSave(t, nomFichier)
%DBSAVE Écrit la table dans un fichier CSV.
%   DBSAVE(T,FICHIER) écrit la table : une première ligne d'en-tête avec
%   les noms de colonnes, puis une ligne par enregistrement, les champs
%   séparés par des virgules.
%
%   Le CSV est le seul format qu'à peu près tout sait lire. Il ne porte
%   pas les types : c'est DBLOAD qui les rétablit, en reconnaissant ce qui
%   se convertit en nombre.
%
%   Exemple :
%      dbSave(t, 'personnel.csv');
%      relue = dbLoad('personnel.csv');
%
%   Voir aussi DBLOAD, DBTABLE.
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
