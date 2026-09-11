function fichiers = matlibre_datastore_fichiers(chemin, extensions)
%MATLIBRE_DATASTORE_FICHIERS Les fichiers désignés par un chemin.
%   Accepte un fichier, une cellule ou un tableau de chaînes de fichiers,
%   un dossier — dont on prend les fichiers dont l'extension convient —,
%   ou un motif à joker.
%
%   Les fichiers d'un dossier sont rendus en ordre alphabétique : sans
%   cela, le contenu d'un magasin dépendrait de l'ordre où le système de
%   fichiers les rend, qui n'est pas le même partout.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      f = [tempname '.csv'];
%      writelines("a,b", f);
%      numel(matlibre_datastore_fichiers(f, {'.csv'}))   % 1
%      delete(f);
%
%   Voir aussi TABULARTEXTDATASTORE, DATASTORE, DIR.
    fichiers = {};
    if iscell(chemin) || (isstring(chemin) && numel(chemin) > 1)
        liste = cellstr(chemin);
        for k = 1:numel(liste)
            fichiers = [fichiers, matlibre_datastore_fichiers(liste{k}, extensions)];  %#ok<AGROW>
        end
        return
    end
    nom = char(string(chemin));
    if exist(nom, 'dir') == 7
        contenu = dir(nom);
        noms = {};
        for k = 1:numel(contenu)
            if contenu(k).isdir
                continue
            end
            [~, ~, extension] = fileparts(contenu(k).name);
            if isempty(extensions) || any(strcmpi(extension, extensions))
                noms{end + 1} = fullfile(nom, contenu(k).name);   %#ok<AGROW>
            end
        end
        fichiers = sort(noms);
        return
    end
    if ~isempty(strfind(nom, '*'))
        dossier = fileparts(nom);
        if isempty(dossier), dossier = '.'; end
        contenu = dir(nom);
        noms = {};
        for k = 1:numel(contenu)
            if ~contenu(k).isdir
                noms{end + 1} = fullfile(dossier, contenu(k).name);   %#ok<AGROW>
            end
        end
        fichiers = sort(noms);
        return
    end
    if exist(nom, 'file') == 2
        fichiers = {nom};
    end
end
