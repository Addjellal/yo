function c = softplusLayer(varargin)
%SOFTPLUSLAYER Redresseur adouci, log(1+exp(X)).
%   C = SOFTPLUSLAYER() rend une sortie toujours positive et dérivable
%   partout — sa dérivée est la sigmoïde. On l'emploie là où une sortie
%   doit rester positive, un écart type par exemple.
%
%   Exemple :
%      c = softplusLayer();
%
%   Voir aussi RELULAYER, GELULAYER, SWISHLAYER.
    c = struct('type', 'softplus', 'nom', matlibre_couche_nom(varargin));
end
