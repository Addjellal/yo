function c = averagePooling1dLayer(taille, varargin)
%AVERAGEPOOLING1DLAYER Agrégation par la moyenne, en une dimension.
%   C = AVERAGEPOOLING1DLAYER(T) remplace chaque fenêtre de T positions
%   par sa moyenne. C'est le sous-échantillonnage d'un signal ou d'une
%   séquence : la sortie est plus courte et moins bruitée.
%
%   Options : 'Stride' (la taille de la fenêtre), 'Padding' (0 ou 'same').
%
%   Exemple :
%      c = averagePooling1dLayer(2);
%
%   Voir aussi MAXPOOLING1DLAYER, AVERAGEPOOLING2DLAYER, AVGPOOL.
    [pas, marge] = matlibre_couche_agregation(taille, varargin);
    c = struct('type', 'avgpool1d', 'taille', taille, 'pas', pas, ...
               'marge', marge, 'nom', matlibre_couche_nom(varargin));
end
