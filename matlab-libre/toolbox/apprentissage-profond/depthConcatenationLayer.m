function c = depthConcatenationLayer(entrees, varargin)
%DEPTHCONCATENATIONLAYER Mise bout à bout selon les canaux.
%   C = DEPTHCONCATENATIONLAYER(N) empile ses N entrées selon la
%   dimension des canaux ; leurs tailles spatiales doivent coïncider.
%   C'est la couche des blocs à branches parallèles, où plusieurs filtres
%   de tailles différentes examinent la même image.
%
%   Exemple :
%      c = depthConcatenationLayer(3, 'Name', 'branches');
%
%   Voir aussi CONCATENATIONLAYER, ADDITIONLAYER, LAYERGRAPH.
    c = struct('type', 'depthconcat', 'entrees', entrees, ...
    'nom', matlibre_couche_nom(varargin));
end
