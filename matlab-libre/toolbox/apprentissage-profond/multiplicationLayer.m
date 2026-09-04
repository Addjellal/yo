function c = multiplicationLayer(entrees, varargin)
%MULTIPLICATIONLAYER Produit terme à terme de plusieurs entrées.
%   C = MULTIPLICATIONLAYER(N) multiplie ses N entrées terme à terme.
%   C'est la couche des portes d'attention : une entrée module l'autre.
%
%   Exemple :
%      c = multiplicationLayer(2, 'Name', 'porte');
%
%   Voir aussi ADDITIONLAYER, CONCATENATIONLAYER, LAYERGRAPH.
    c = struct('type', 'multiplication', 'entrees', entrees, ...
    'nom', matlibre_couche_nom(varargin));
end
