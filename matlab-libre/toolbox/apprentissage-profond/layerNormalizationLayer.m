function c = layerNormalizationLayer(varargin)
%LAYERNORMALIZATIONLAYER Normalisation par observation.
%   C = LAYERNORMALIZATIONLAYER() centre et réduit chaque observation sur
%   ses propres canaux, puis applique un gain et un décalage appris. Le
%   résultat d'une observation ne dépend d'aucune autre : la couche
%   fonctionne donc avec un lot d'un seul exemple, là où la normalisation
%   par lot demande un lot fourni.
%
%   Option : 'Epsilon' (1e-5).
%
%   Exemple :
%      c = layerNormalizationLayer('Name', 'norme');
%
%   Voir aussi BATCHNORMALIZATIONLAYER, GROUPNORMALIZATIONLAYER, LAYERNORM.
    epsilon = 1e-5;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'epsilon')
            epsilon = double(varargin{k + 1});
        end
    end
    c = struct('type', 'layernorm', 'epsilon', epsilon, 'gamma', [], 'beta', [], ...
    'nom', matlibre_couche_nom(varargin));
end
