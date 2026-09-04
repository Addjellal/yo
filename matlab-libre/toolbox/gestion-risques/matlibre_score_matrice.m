function X = matlibre_score_matrice(grille, variables, colonnes)
%MATLIBRE_SCORE_MATRICE Matrice des poids de la preuve.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 3 || isempty(colonnes)
        colonnes = grille.Data;
    end
    premiere = colonnes.(variables{1});
    n = numel(premiere);
    X = zeros(n, numel(variables));
    for j = 1:numel(variables)
        nom = variables{j};
        indices = matlibre_score_indices(grille, nom, colonnes.(nom));
        X(:, j) = matlibre_score_poids(grille, nom, indices);
    end
end
