function c = crossChannelNormalizationLayer(fenetre, varargin)
%CROSSCHANNELNORMALIZATIONLAYER Normalisation locale entre canaux.
%   C = CROSSCHANNELNORMALIZATIONLAYER(F) divise chaque activation par une
%   fonction de la somme des carrés des activations voisines dans les
%   canaux, sur une fenêtre de F canaux. Les canaux se font ainsi
%   concurrence à chaque position : un canal fortement excité éteint ses
%   voisins.
%
%   Options et valeurs par défaut : 'Alpha' (1e-4), 'Beta' (0.75), 'K' (2).
%
%   Exemple :
%      c = crossChannelNormalizationLayer(5);
%
%   Voir aussi BATCHNORMALIZATIONLAYER, GROUPNORMALIZATIONLAYER.
    alpha = 1e-4;
    beta = 0.75;
    K = 2;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'alpha', alpha = double(varargin{k + 1});
            case 'beta',  beta = double(varargin{k + 1});
            case 'k',     K = double(varargin{k + 1});
        end
    end
    c = struct('type', 'crosschannelnorm', 'fenetre', fenetre, 'alpha', alpha, ...
               'beta', beta, 'K', K, 'nom', matlibre_couche_nom(varargin));
end
