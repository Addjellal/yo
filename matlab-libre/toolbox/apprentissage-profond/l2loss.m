function perte = l2loss(predit, cible, varargin)
%L2LOSS Somme des carrés des écarts.
%   P = L2LOSS(Y,T) rend la somme des carrés des écarts, divisée par le
%   nombre d'observations.
%
%   Options et valeurs par défaut :
%     'Reduction'             'sum', ou 'none'
%     'NormalizationFactor'   'batch-size', 'all-elements' ou 'none'
%     'DataFormat'            le format, quand Y n'en porte pas
%
%   Exemple :
%      l2loss(dlarray([1 2], 'CB'), [0 0])      % 2.5
%
%   Voir aussi L1LOSS, HUBER, MSE.
    [reduction, facteur, format] = matlibre_dl_options_perte(predit, varargin);
    perte = matlibre_dl_reduire_perte((predit - cible) .^ 2, reduction, facteur, format);
end
