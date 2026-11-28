function j = matlibre_db_colonne(t, nom, fonction)
%MATLIBRE_DB_COLONNE Le rang d'une colonne, ou une erreur qui la nomme.
%   J = MATLIBRE_DB_COLONNE(T,NOM,FONCTION) rend le rang de la colonne NOM
%   de la table T. Une colonne inconnue est refusée en le disant : une
%   requête qui porterait sur rien ne doit pas réussir en silence.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi DBUPDATE, DBGROUPSUM.
    j = find(strcmp(t.colonnes, char(nom)), 1);
    if isempty(j)
        error(sprintf('database:%s:colonneInconnue', fonction), ...
              'The table has no column ''%s'' (columns: %s).', ...
              char(nom), strjoin(t.colonnes, ', '));
    end
end
