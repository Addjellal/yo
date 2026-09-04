function probabilites = probdefault(grille, donnees)
%PROBDEFAULT Probabilité de défaut selon une grille de score.
%   P = PROBDEFAULT(SC) rend la probabilité de défaut de chaque dossier
%   ayant servi à l'ajustement ; PROBDEFAULT(SC,DONNEES) en traite
%   d'autres.
%
%   Elle ne dépend pas de l'échelle des points : celle-ci ne fait que
%   déplacer et étirer le score, et la transformation inverse la rend
%   telle quelle.
%
%   Exemple :
%      p = probdefault(sc);
%
%   Voir aussi SCORE, VALIDATEMODEL, FITMODEL.
    if nargin < 2
        donnees = [];
    end
    scores = score(grille, donnees);
    % Retour à l'échelle du modèle, puis lien logistique inverse.
    lineaire = (scores - grille.Shift) / grille.Slope;
    probabilites = 1 ./ (1 + exp(lineaire));
end
