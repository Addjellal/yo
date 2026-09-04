function M = matlibre_retards(serie, retards, lignes)
%MATLIBRE_RETARDS Matrice des valeurs retardées d'une série.
%   Colonne j : la série décalée de j pas, prise aux indices LIGNES.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    serie = serie(:);
    lignes = lignes(:);
    M = zeros(numel(lignes), retards);
    for j = 1:retards
        M(:, j) = serie(lignes - j);
    end
end
