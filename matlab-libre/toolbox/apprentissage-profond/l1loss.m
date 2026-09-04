function perte = l1loss(predit, cible, varargin)
%L1LOSS Somme des écarts absolus.
%   P = L1LOSS(Y,T) rend la somme des valeurs absolues des écarts,
%   divisée par le nombre d'observations.
%
%   Cette perte pénalise proportionnellement à l'écart, là où la perte
%   quadratique pénalise au carré : une observation aberrante y pèse
%   beaucoup moins, ce qui rend l'ajustement robuste.
%
%   Options et valeurs par défaut :
%     'Reduction'             'sum', ou 'none' pour garder les termes
%     'NormalizationFactor'   'batch-size', 'all-elements' ou 'none'
%     'DataFormat'            le format, quand Y n'en porte pas
%
%   Exemple :
%      l1loss(dlarray([1 2], 'CB'), [0 0])      % 1.5
%
%   Voir aussi L2LOSS, HUBER, MSE, CROSSENTROPY.
    [reduction, facteur, format] = matlibre_dl_options_perte(predit, varargin);
    perte = matlibre_dl_reduire_perte(abs(predit - cible), reduction, facteur, format);
end
