function [statistiques, tableau] = validatemodel(grille, donnees)
%VALIDATEMODEL Pouvoir discriminant d'une grille de score.
%   [S,T] = VALIDATEMODEL(SC) rend l'aire sous la courbe de sensibilité,
%   le coefficient de Gini et la statistique de Kolmogorov-Smirnov, ainsi
%   que le tableau qui a servi à les calculer.
%
%   L'aire sous la courbe est la probabilité qu'un bon dossier tiré au
%   hasard reçoive un score plus élevé qu'un mauvais : un demi pour un
%   modèle qui ne sait rien, un pour un modèle parfait. Le coefficient de
%   Gini en est la version centrée, et la statistique de
%   Kolmogorov-Smirnov le plus grand écart entre les deux répartitions.
%
%   Exemple :
%      s = validatemodel(sc);
%      s.AUROC
%
%   Voir aussi SCORE, PROBDEFAULT, FITMODEL.
    if nargin < 2
        donnees = [];
    end
    scores = score(grille, donnees);
    if isempty(donnees)
        [bons, ~, ~] = matlibre_score_reponse(grille);
    else
        colonnes = matlibre_score_colonnes(donnees);
        reponse = colonnes.(grille.ResponseVar);
        if iscell(reponse)
            bons = double(strcmp(reponse(:), grille.GoodLabel));
        else
            bons = double(double(reponse(:)) == grille.GoodLabel);
        end
    end
    [scoresTries, ordre] = sort(scores);
    bonsTries = bons(ordre);
    totalBons = sum(bonsTries);
    totalMauvais = numel(bonsTries) - totalBons;
    cumulBons = cumsum(bonsTries) / max(totalBons, eps);
    cumulMauvais = cumsum(1 - bonsTries) / max(totalMauvais, eps);
    % Aire sous la courbe : en abscisse la part des bons déjà franchie,
    % en ordonnée celle des mauvais. Les scores étant triés par ordre
    % croissant, cette aire est exactement la probabilité qu'un mauvais
    % dossier reçoive un score inférieur à celui d'un bon.
    aire = trapz([0; cumulBons], [0; cumulMauvais]);
    ks = max(abs(cumulMauvais - cumulBons));
    statistiques = struct('AUROC', aire, 'Gini', 2 * aire - 1, 'KS', ks, ...
                          'KSScore', scoresTries(find(abs(cumulMauvais - cumulBons) == ks, 1)));
    if nargout > 1
        tableau = struct('Scores', scoresTries, 'CumulativeBad', cumulMauvais, ...
                         'CumulativeGood', cumulBons);
    end
end
