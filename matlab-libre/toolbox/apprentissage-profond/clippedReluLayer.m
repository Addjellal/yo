function c = clippedReluLayer(plafond, varargin)
%CLIPPEDRELULAYER Redresseur borné.
%   C = CLIPPEDRELULAYER(PLAFOND) applique min(max(X,0),PLAFOND). Le
%   plafond empêche les activations de croître sans limite, ce qui rend
%   l'apprentissage plus stable et la quantification possible.
%
%   Exemple :
%      c = clippedReluLayer(6);
%
%   Voir aussi RELULAYER, LEAKYRELULAYER, ELULAYER.
    c = struct('type', 'clippedrelu', 'plafond', plafond, ...
    'nom', matlibre_couche_nom(varargin));
end
