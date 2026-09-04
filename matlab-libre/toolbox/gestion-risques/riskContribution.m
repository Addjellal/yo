function [contributions, risque] = riskContribution(entree, covariance)
%RISKCONTRIBUTION Contribution de chaque composant au risque total.
%   C = RISKCONTRIBUTION(POIDS,COVARIANCE) rend la contribution marginale
%   de chaque actif à l'écart type d'un portefeuille : le poids multiplié
%   par la dérivée du risque par rapport à ce poids. Les contributions
%   somment exactement au risque, ce qui est la propriété qu'on attend
%   d'une décomposition.
%
%   C = RISKCONTRIBUTION(MODELE) décompose au contraire les pertes d'un
%   portefeuille de crédit simulé : la perte attendue, l'écart type, la
%   valeur en risque et la perte moyenne au-delà sont réparties entre les
%   contreparties. La part de valeur en risque d'une contrepartie est sa
%   perte moyenne dans les scénarios où la perte totale avoisine le
%   quantile — c'est ce qui rend la somme des parts égale au total.
%
%   Exemple :
%      riskContribution([0.5 0.5], [0.04 0.01; 0.01 0.09])
%      riskContribution(simulate(copule, 20000))
%
%   Voir aussi PORTFOLIORISK, CONFIDENCEBANDS, CREDITDEFAULTCOPULA.
    if matlibre_est_copule(entree)
        [contributions, risque] = matlibre_contribution_credit(entree);
        return
    end
    poids = entree(:);
    risque = sqrt(poids.' * covariance * poids);
    if risque == 0
        contributions = zeros(size(poids));
    else
        contributions = poids .* (covariance * poids) / risque;
    end
end
