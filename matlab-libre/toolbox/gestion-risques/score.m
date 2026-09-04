function [scores, points] = score(grille, donnees)
%SCORE Note des dossiers par une grille de score.
%   [S,P] = SCORE(SC) note les dossiers qui ont servi à l'ajustement ;
%   SCORE(SC,DONNEES) en note d'autres. P donne les points par
%   caractéristique, dont S est la somme.
%
%   Un score élevé désigne un bon dossier : la régression modélise la
%   probabilité de ne pas faire défaut.
%
%   Exemple :
%      [s, p] = score(sc, nouveauxDossiers);
%
%   Voir aussi PROBDEFAULT, DISPLAYPOINTS, FORMATPOINTS, VALIDATEMODEL.
    if isempty(grille.ModelVars)
        error('risque:score:Modele', ...
              'Il faut ajuster le modèle avant de noter.');
    end
    if nargin < 2 || isempty(donnees)
        colonnes = grille.Data;
    else
        colonnes = matlibre_score_colonnes(donnees);
    end
    variables = grille.ModelVars;
    coefficients = grille.ModelCoefficients;
    nombre = numel(variables);
    X = matlibre_score_matrice(grille, variables, colonnes);
    points = zeros(size(X));
    for j = 1:nombre
        brut = coefficients(j + 1) * X(:, j) + coefficients(1) / nombre;
        points(:, j) = grille.Shift / nombre + grille.Slope * brut;
    end
    scores = sum(points, 2);
end
