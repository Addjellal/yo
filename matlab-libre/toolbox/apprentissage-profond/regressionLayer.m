function c = regressionLayer(varargin)
%REGRESSIONLAYER Couche de sortie pour la régression.
%   Elle déclare que le coût est l'erreur quadratique moyenne.
    c = struct('type', 'regression', 'nom', matlibre_couche_nom(varargin));
end
