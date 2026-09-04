function [indices, etiquettes] = matlibre_score_indices(grille, nom, colonne)
%MATLIBRE_SCORE_INDICES Numéro et nom de tranche de chaque observation.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    tranche = matlibre_score_tranche(grille, nom);
    if isempty(tranche)
        error('risque:creditscorecard:Tranche', ...
              'La variable %s n''est pas encore découpée : appelez AUTOBINNING.', nom);
    end
    if strcmp(tranche.type, 'categorie')
        categories = tranche.categories;
        indices = zeros(numel(colonne), 1);
        for k = 1:numel(colonne)
            rang = find(strcmp(categories, colonne{k}), 1);
            if isempty(rang)
                indices(k) = numel(categories) + 1;
            else
                indices(k) = rang;
            end
        end
        etiquettes = [categories(:).', {'<autre>'}];
    else
        indices = matlibre_score_rang(colonne, tranche.bornes);
        bornes = tranche.bornes;
        etiquettes = cell(1, numel(bornes) + 2);
        if isempty(bornes)
            etiquettes{1} = '(-Inf, Inf)';
        else
            etiquettes{1} = sprintf('(-Inf, %g]', bornes(1));
            for k = 2:numel(bornes)
                etiquettes{k} = sprintf('(%g, %g]', bornes(k - 1), bornes(k));
            end
            etiquettes{numel(bornes) + 1} = sprintf('(%g, Inf)', bornes(end));
        end
        etiquettes{end} = '<manquant>';
    end
end
