function c = groupNormalizationLayer(groupes, varargin)
%GROUPNORMALIZATIONLAYER Normalisation par groupe de canaux.
%   C = GROUPNORMALIZATIONLAYER(G) partage les canaux en G groupes et
%   normalise chacun séparément, observation par observation. Elle occupe
%   le milieu entre la normalisation par couche — un seul groupe — et la
%   normalisation par instance — un groupe par canal.
%
%   G peut aussi valoir 'channel-wise' ou 'all-channels'.
%   Option : 'Epsilon' (1e-5).
%
%   Exemple :
%      c = groupNormalizationLayer(4);
%
%   Voir aussi BATCHNORMALIZATIONLAYER, LAYERNORMALIZATIONLAYER, GROUPNORM.
    epsilon = 1e-5;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'epsilon')
            epsilon = double(varargin{k + 1});
        end
    end
    c = struct('type', 'groupnorm', 'groupes', groupes, 'epsilon', epsilon, ...
               'gamma', [], 'beta', [], 'nom', matlibre_couche_nom(varargin));
end
