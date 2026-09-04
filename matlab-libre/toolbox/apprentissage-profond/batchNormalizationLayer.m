function c = batchNormalizationLayer(varargin)
%BATCHNORMALIZATIONLAYER Normalisation par lot.
%   Centre et réduit chaque composante sur le lot, puis applique un gain
%   et un décalage appris. Les moyennes glissantes servent à la
%   prédiction.
    c = struct('type', 'batchnorm', 'epsilon', 1e-5, 'gamma', [], 'beta', [], ...
               'moyenne', [], 'variance', [], ...
               'nom', matlibre_couche_nom(varargin));
end
