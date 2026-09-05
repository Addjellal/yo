function A = matlibre_id_base_tendance(t, ordre)
%MATLIBRE_ID_BASE_TENDANCE Base des tendances polynomiales.
%   A = MATLIBRE_ID_BASE_TENDANCE(T,ORDRE) rend la matrice des puissances
%   de T jusqu'à ORDRE : une colonne de uns pour la moyenne, plus le temps
%   lui-même pour une dérive.
%
%   Exemple :
%      matlibre_id_base_tendance([1; 2], 1)      % [1 1; 1 2]
%
%   Voir aussi DETREND, RETREND.
    t = t(:);
    A = ones(numel(t), ordre + 1);
    for k = 1:ordre
        A(:, k + 1) = t .^ k;
    end
end
