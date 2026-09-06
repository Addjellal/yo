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
%      rng(1);
%      n = 500;
%      revenu = 20000 + 40000 * rand(n, 1);
%      age = round(20 + 45 * rand(n, 1));
%      risque = -1 + 3 * (revenu - 40000) / 20000;
%      defaut = double(rand(n, 1) > 1 ./ (1 + exp(-risque)));
%      donnees = struct('id', (1:n)', 'revenu', revenu, 'age', age, ...
%                       'defaut', defaut);
%      sc = creditscorecard(donnees, 'IDVar', 'id', 'ResponseVar', 'defaut', ...
%                           'GoodLabel', 0);
%      sc = autobinning(sc);
%      sc = fitmodel(sc);
%      [s, p] = score(sc);
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
