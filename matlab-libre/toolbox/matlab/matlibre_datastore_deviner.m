function type = matlibre_datastore_deviner(chemin)
%MATLIBRE_DATASTORE_DEVINER Le genre de magasin qui convient à un chemin.
%   L'extension décide : .csv, .txt et .dat donnent un magasin de texte
%   tabulaire ; .pgm, .ppm, .png et .jpg un magasin d'images. Un dossier
%   est jugé d'après ce qu'il contient.
%
%   Deviner vaut mieux qu'exiger, mais pas toujours : quand rien ne
%   tranche, on rend le texte tabulaire, qui est le cas courant, et
%   'Type' permet de dire autre chose.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      strcmp(matlibre_datastore_deviner('mesures.csv'), 'tabulartext')
%
%   Voir aussi DATASTORE.
    images = {'.pgm', '.ppm', '.png', '.jpg', '.jpeg', '.bmp'};
    nom = char(string(chemin));
    if iscell(chemin) || (isstring(chemin) && numel(chemin) > 1)
        liste = cellstr(chemin);
        nom = liste{1};
    end
    if exist(nom, 'dir') == 7
        contenu = dir(nom);
        for k = 1:numel(contenu)
            if contenu(k).isdir
                continue
            end
            [~, ~, extension] = fileparts(contenu(k).name);
            if any(strcmpi(extension, images))
                type = 'image';
                return
            end
        end
        type = 'tabulartext';
        return
    end
    [~, ~, extension] = fileparts(nom);
    if any(strcmpi(extension, images))
        type = 'image';
    else
        type = 'tabulartext';
    end
end
