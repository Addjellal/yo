function c = concatenationLayer(dimension, entrees, varargin)
%CONCATENATIONLAYER Mise bout à bout de plusieurs entrées.
%   C = CONCATENATIONLAYER(DIM,N) met ses N entrées bout à bout selon la
%   dimension DIM. Contrairement à l'addition, elle n'exige pas que les
%   entrées aient la même taille selon cette dimension, et elle garde
%   toute leur information.
%
%   Exemple :
%      c = concatenationLayer(1, 2, 'Name', 'jointure');
%
%   Voir aussi DEPTHCONCATENATIONLAYER, ADDITIONLAYER, LAYERGRAPH.
    c = struct('type', 'concatenation', 'dimension', dimension, ...
               'entrees', entrees, 'nom', matlibre_couche_nom(varargin));
end
