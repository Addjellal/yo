function variance = portvar(rendements, poids)
%PORTVAR Variance d'un portefeuille.
%   V = PORTVAR(RENDEMENTS,POIDS) rend la variance du portefeuille dont
%   les poids sont donnés, la covariance étant estimée sur les
%   rendements.
%
%   La variance d'un portefeuille n'est pas la moyenne des variances :
%   elle est plus petite dès que les actifs ne sont pas parfaitement
%   corrélés. C'est toute la diversification.
%
%   Exemple :
%      portvar(randn(200, 3), [0.5 0.3 0.2])
%
%   Voir aussi PORTSTATS, PORTOPT, PORTALLOC, COV.
    rendements = double(rendements);
    covariance = cov(rendements);
    poids = double(poids(:));
    variance = poids.' * covariance * poids;
end
