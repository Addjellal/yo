function [indices, classes] = matlibre_dl_indices_classes(etiquettes, classes)
%MATLIBRE_DL_INDICES_CLASSES Numéro de classe de chaque étiquette.
%   [I,C] = MATLIBRE_DL_INDICES_CLASSES(E,C) rend le numéro de la classe
%   de chaque étiquette et la liste des classes. Une liste imposée est
%   respectée, y compris son ordre ; sinon les classes sont celles que
%   portent les étiquettes.
%
%   Exemple :
%      [i, c] = matlibre_dl_indices_classes({'b','a'}, {});
%      i      % 2 1
%
%   Voir aussi ONEHOTENCODE, ONEHOTDECODE.
    if iscategorical(etiquettes)
        noms = cellstr(etiquettes);
        if isempty(classes)
            classes = categories(etiquettes);
        end
    elseif iscell(etiquettes)
        noms = etiquettes;
    elseif ischar(etiquettes)
        noms = cellstr(etiquettes);
    else
        valeurs = double(etiquettes(:));
        if isempty(classes)
            classes = unique(valeurs);
        end
        indices = zeros(numel(valeurs), 1);
        liste = double(classes);
        for k = 1:numel(valeurs)
            position = find(liste == valeurs(k), 1);
            if ~isempty(position)
                indices(k) = position;
            end
        end
        classes = num2cell(liste(:));
        return
    end
    noms = noms(:);
    if isempty(classes)
        classes = unique(noms);
    elseif iscategorical(classes)
        classes = cellstr(classes);
    end
    indices = zeros(numel(noms), 1);
    for k = 1:numel(noms)
        position = find(strcmp(classes, noms{k}), 1);
        if ~isempty(position)
            indices(k) = position;
        end
    end
end
