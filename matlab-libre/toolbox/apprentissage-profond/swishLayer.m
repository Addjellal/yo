function c = swishLayer(varargin)
%SWISHLAYER Activation X fois sigmoïde de X.
%   C = SWISHLAYER() applique X./(1+exp(-X)). Comme la gaussienne à
%   porte, elle est lisse et laisse passer un peu de négatif, ce qui
%   entretient le gradient là où le redresseur l'annule.
%
%   Exemple :
%      c = swishLayer();
%
%   Voir aussi GELULAYER, RELULAYER, SOFTPLUSLAYER.
    c = struct('type', 'swish', 'nom', matlibre_couche_nom(varargin));
end
