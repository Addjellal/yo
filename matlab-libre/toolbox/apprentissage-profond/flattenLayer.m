function c = flattenLayer(varargin)
%FLATTENLAYER Aplatit un lot d'images en vecteurs.
%   Un tableau H x L x P x N devient une matrice (H*L*P) x N, prête pour
%   les couches entièrement connectées.
    c = struct('type', 'flatten', 'forme', [], 'nom', matlibre_couche_nom(varargin));
end
