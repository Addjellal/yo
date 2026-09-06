function e = expectedShortfall(rendements, niveau)
%EXPECTEDSHORTFALL Perte moyenne conditionnelle au-delà de la VaR.
%   E = EXPECTEDSHORTFALL(RENDEMENTS) rend la perte moyenne dans les 5 %
%   des cas les plus défavorables, comptée positivement.
%   E = EXPECTEDSHORTFALL(RENDEMENTS,NIVEAU) change le niveau de confiance,
%   0,95 par défaut.
%
%   La valeur en risque dit combien on perd au pire dans 95 % des cas ;
%   elle ne dit rien des 5 % restants, où la perte peut être dix fois
%   supérieure sans que le chiffre bouge. La perte attendue au-delà, elle,
%   moyenne précisément cette queue : c'est la question qu'un régulateur
%   pose, et c'est pourquoi Bâle III l'a substituée à la valeur en risque.
%
%   Elle est de plus sous-additive : le risque d'un portefeuille n'excède
%   jamais la somme des risques de ses composantes. La valeur en risque ne
%   l'est pas — diversifier peut l'augmenter, ce qui est absurde pour une
%   mesure de risque et interdit de l'agréger d'un pupitre à l'autre.
%
%   L'estimation est empirique : elle ne suppose aucune loi, mais ne
%   repose que sur les quelques points de la queue observée, et sa
%   variance est donc élevée sur un historique court.
%
%   Exemple :
%      rng(1);
%      e = expectedShortfall(0.01 * randn(1000, 1), 0.95);
%
%   Voir aussi MAXDRAWDOWN, DRAWDOWNSERIES, QUANTILE.
    if nargin < 2
        niveau = 0.95;
    end
    r = rendements(:);
    seuil = quantile(r, 1 - niveau);
    queue = r(r <= seuil);
    if isempty(queue)
        e = -seuil;
    else
        e = -mean(queue);
    end
end
