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
