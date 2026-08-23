function c = flattenLayer()
%FLATTENLAYER Aplatit un lot d'images en vecteurs.
%   Un tableau H x L x P x N devient une matrice (H*L*P) x N, prête pour
%   les couches entièrement connectées.
    c = struct('type', 'flatten', 'forme', []);
end
