function [rendement, risque] = portstats(rendements, covariance, poids)
%PORTSTATS Rendement et écart type d'un portefeuille.
    poids = poids(:);
    rendement = rendements(:).' * poids;
    risque = sqrt(poids.' * covariance * poids);
end
