function dbSave(t, nomFichier)
%DBSAVE Écrit la table dans un fichier CSV.
%   DBSAVE(T,FICHIER) écrit la table : une première ligne d'en-tête avec
%   les noms de colonnes, puis une ligne par enregistrement, les champs
%   séparés par des virgules.
%
%   Le fichier suit RFC 4180, ce que lisent les tableurs, Python (csv) et
%   SQLite : le texte est entre guillemets, ses guillemets doublés — une
%   virgule ou un retour à la ligne dans un nom ne casse rien —, et les
%   nombres s'écrivent avec dix-sept chiffres significatifs, ce qui les
%   relit exactement. Les guillemets portent aussi le type : DBLOAD rend
%   en texte ce qui était du texte, « 007 » compris.
%
%   Exemple :
%      t = dbTable({'nom', 'service', 'salaire', 'anciennete'});
%      t = dbInsert(t, {'Dupont', 'etudes', 45000, 6});
%      t = dbInsert(t, {'Martin', 'ventes', 38000, 3});
%      dbSave(t, 'personnel.csv');
%      relue = dbLoad('personnel.csv');
%
%   Voir aussi DBLOAD, DBTABLE.
    fid = fopen(nomFichier, 'w');
    if fid < 0
        error('database:dbSave:Ouverture', 'Unable to write file ''%s''.', nomFichier);
    end
    fprintf(fid, '%s\n', strjoin(cellfun(@champ, t.colonnes, 'UniformOutput', false), ','));
    for i = 1:numel(t.lignes)
        fprintf(fid, '%s\n', strjoin(cellfun(@champ, t.lignes{i}, 'UniformOutput', false), ','));
    end
    fclose(fid);
end

% Un champ CSV (RFC 4180) : le texte entre guillemets, ses guillemets
% doublés ; un nombre avec dix-sept chiffres, qui le relisent exactement.
function texte = champ(v)
    if ischar(v) || isstring(v)
        texte = ['"' strrep(char(v), '"', '""') '"'];
    elseif islogical(v)
        texte = sprintf('%d', v);
    else
        texte = sprintf('%.17g', v);
    end
end
