function [indices, classes] = matlibre_etiquettes_communes(etiquettes, autres, ordre)
%MATLIBRE_ETIQUETTES_COMMUNES Numérote deux jeux d'étiquettes ensemble.
%   [I,C] = MATLIBRE_ETIQUETTES_COMMUNES(E,AUTRES,ORDRE) rend le numéro de
%   classe de chaque étiquette de E et la liste des classes, prise sur la
%   réunion de E et de AUTRES — sans quoi une classe absente d'un des deux
%   jeux décalerait les lignes par rapport aux colonnes.
%
%   ORDRE, s'il est donné, impose la liste et son ordre.
%
%   Exemple :
%      [i, c] = matlibre_etiquettes_communes({'b'}, {'a'}, {});
%      i      % 2
%
%   Voir aussi CONFUSIONMAT.
    texte = matlibre_etiquettes_texte(etiquettes);
    autresTexte = matlibre_etiquettes_texte(autres);
    if isempty(ordre)
        classes = unique([texte; autresTexte]);
    else
        classes = matlibre_etiquettes_texte(ordre);
    end
    indices = zeros(numel(texte), 1);
    for k = 1:numel(texte)
        position = find(strcmp(classes, texte{k}), 1);
        if ~isempty(position)
            indices(k) = position;
        end
    end
    if isnumeric(etiquettes) && (isempty(ordre) || isnumeric(ordre))
        nombres = zeros(numel(classes), 1);
        for k = 1:numel(classes)
            nombres(k) = str2double(classes{k});
        end
        if ~any(isnan(nombres))
            [nombres, rang] = sort(nombres);
            reordonne = zeros(size(indices));
            [~, inverse] = sort(rang);
            for k = 1:numel(indices)
                if indices(k) > 0
                    reordonne(k) = inverse(indices(k));
                end
            end
            indices = reordonne;
            classes = nombres;
        end
    end
end
