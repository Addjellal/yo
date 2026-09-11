function info = parquetinfo(nomFichier)
%PARQUETINFO Renseigne sur un fichier Parquet sans le lire.
%   I = PARQUETINFO(FICHIER) rend une structure décrivant le fichier :
%   son chemin, le nombre de lignes, le nombre de groupes de lignes, les
%   noms des variables et leurs classes.
%
%   Seul le pied du fichier est lu. C'est ce qui permet de savoir ce que
%   contient un fichier de plusieurs gigaoctets sans en ouvrir une
%   colonne.
%
%   Exemple :
%      f = fullfile(tempdir, 'info.parquet');
%      parquetwrite(f, table([1; 2], ["x"; "y"], 'VariableNames', {'a', 'b'}));
%      i = parquetinfo(f);
%      i.NumRows                       % 2
%      i.VariableNames{2}              % 'b'
%
%   Voir aussi PARQUETREAD, PARQUETWRITE.
    if nargin < 1
        error('MATLAB:minrhs', 'PARQUETINFO attend un nom de fichier.');
    end
    nomFichier = char(nomFichier);
    metadonnees = matlibre_parquet_pied(nomFichier);
    schema = metadonnees.c2;
    noms = {};
    classes = {};
    for k = 2:numel(schema)
        element = schema{k};
        noms{end+1} = char(native2unicode(element.c4, 'UTF-8'));   %#ok<AGROW>
        converti = -1;
        if isfield(element, 'c6')
            converti = double(element.c6);
        end
        classes{end+1} = matlibre_parquet_classe(double(element.c1), converti);   %#ok<AGROW>
    end
    creePar = '';
    if isfield(metadonnees, 'c6')
        creePar = char(native2unicode(metadonnees.c6, 'UTF-8'));
    end
    info = struct('Filename', nomFichier, ...
                  'NumRows', double(metadonnees.c3), ...
                  'NumRowGroups', numel(metadonnees.c4), ...
                  'VariableNames', {noms}, ...
                  'VariableTypes', {classes}, ...
                  'CreatedBy', creePar);
end
