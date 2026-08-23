function c = imageInputLayer(taille, varargin)
%IMAGEINPUTLAYER Couche d'entrée pour des images.
%   C = IMAGEINPUTLAYER([H L P]) déclare des images de H lignes, L
%   colonnes et P plans. Les données passées à TRAINNETWORK sont alors un
%   tableau H x L x P x N, une image par tranche.
%
%   Exemple :
%      couches = {imageInputLayer([8 8 1]), convolution2dLayer(3, 4), ...
%                 reluLayer(), maxPooling2dLayer(2), flattenLayer(), ...
%                 fullyConnectedLayer(2), softmaxLayer()};
    if numel(taille) < 3, taille(3) = 1; end
    c = struct('type', 'imageinput', 'taille', taille(:)');
end
