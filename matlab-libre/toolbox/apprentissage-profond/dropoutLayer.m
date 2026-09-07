function c = dropoutLayer(probabilite, varargin)
%DROPOUTLAYER Couche d'abandon : éteint des unités pendant l'apprentissage.
%   C = DROPOUTLAYER(P) éteint chaque unité avec la probabilité P et
%   divise le reste par 1-P, de sorte que l'espérance ne change pas.
%   À la prédiction, la couche est transparente.
%
%   Exemple :
%      c = dropoutLayer(0.5);
%      c.probabilite               % 0.5 : une unite sur deux est ecartee a l'apprentissage
%
%   Voir aussi BATCHNORMALIZATIONLAYER, RELULAYER, TRAININGOPTIONS.
    if nargin < 1 || isempty(probabilite), probabilite = 0.5; end
    c = struct('type', 'dropout', 'probabilite', probabilite, 'nom', matlibre_couche_nom(varargin));
end
