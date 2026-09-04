function c = maxPooling1dLayer(taille, varargin)
%MAXPOOLING1DLAYER Agrégation par le maximum, en une dimension.
%   C = MAXPOOLING1DLAYER(T) ne garde de chaque fenêtre de T positions que
%   la plus grande valeur. La sortie ne change pas quand le motif se
%   déplace de moins d'une fenêtre.
%
%   Options : 'Stride' (la taille de la fenêtre), 'Padding' (0 ou 'same').
%
%   Exemple :
%      c = maxPooling1dLayer(3, 'Stride', 1);
%
%   Voir aussi AVERAGEPOOLING1DLAYER, MAXPOOLING2DLAYER, MAXPOOL.
    [pas, marge] = matlibre_couche_agregation(taille, varargin);
    c = struct('type', 'maxpool1d', 'taille', taille, 'pas', pas, ...
               'marge', marge, 'nom', matlibre_couche_nom(varargin));
end
