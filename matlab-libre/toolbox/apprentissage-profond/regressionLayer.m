function c = regressionLayer(varargin)
%REGRESSIONLAYER Couche de sortie pour la régression.
%   Elle déclare que le coût est l'erreur quadratique moyenne.
%
%   Exemple :
%      couches = {featureInputLayer(3), fullyConnectedLayer(1), regressionLayer()};
%      numel(couches)              % 3
%
%   Voir aussi CLASSIFICATIONLAYER, MSE, FULLYCONNECTEDLAYER.
    c = struct('type', 'regression', 'nom', matlibre_couche_nom(varargin));
end
