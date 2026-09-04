function rangs = matlibre_score_rang(colonne, bornes)
%MATLIBRE_SCORE_RANG Numéro de tranche de chaque observation.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    colonne = double(colonne(:));
    rangs = ones(size(colonne));
    for k = 1:numel(bornes)
        rangs(colonne > bornes(k)) = k + 1;
    end
    rangs(isnan(colonne)) = numel(bornes) + 2;
end
