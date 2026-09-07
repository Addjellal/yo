function c = classificationLayer(varargin)
%CLASSIFICATIONLAYER Couche de sortie pour la classification.
%   Elle déclare que le coût est l'entropie croisée ; elle n'a pas de
%   paramètre et ne transforme pas la sortie.
%
%   Exemple :
%      couches = {featureInputLayer(3), fullyConnectedLayer(2), ...
%                 softmaxLayer(), classificationLayer()};
%      numel(couches)              % 4
    c = struct('type', 'classification', 'nom', matlibre_couche_nom(varargin));
end
