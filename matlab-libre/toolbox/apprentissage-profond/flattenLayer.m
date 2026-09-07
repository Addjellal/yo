function c = flattenLayer(varargin)
%FLATTENLAYER Aplatit un lot d'images en vecteurs.
%   Un tableau H x L x P x N devient une matrice (H*L*P) x N, prête pour
%   les couches entièrement connectées.
%
%   Exemple :
%      couches = {imageInputLayer([8 8 1]), flattenLayer(), fullyConnectedLayer(2)};
%      numel(couches)              % 3
    c = struct('type', 'flatten', 'forme', [], 'nom', matlibre_couche_nom(varargin));
end
