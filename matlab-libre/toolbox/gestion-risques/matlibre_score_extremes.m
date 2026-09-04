function [pointsParVariable, extremes] = matlibre_score_extremes(grille)
%MATLIBRE_SCORE_EXTREMES Points non mis à l'échelle, et scores extrêmes.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(grille.ModelVars)
        error('risque:creditscorecard:Modele', ...
              'Il faut ajuster le modèle avant de parler de points.');
    end
    variables = grille.ModelVars;
    coefficients = grille.ModelCoefficients;
    nombre = numel(variables);
    pointsParVariable = cell(1, nombre);
    minimum = 0;
    maximum = 0;
    for j = 1:nombre
        nom = variables{j};
        [~, etiquettes] = matlibre_score_indices(grille, nom, grille.Data.(nom));
        poidsTranches = matlibre_score_poids(grille, nom, (1:numel(etiquettes)).');
        valeurs = coefficients(j + 1) * poidsTranches + coefficients(1) / nombre;
        pointsParVariable{j} = struct('nom', nom, 'etiquettes', {etiquettes}, ...
                                      'points', valeurs);
        minimum = minimum + min(valeurs);
        maximum = maximum + max(valeurs);
    end
    extremes = [minimum, maximum];
end
