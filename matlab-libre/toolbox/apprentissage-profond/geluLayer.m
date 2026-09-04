function c = geluLayer(varargin)
%GELULAYER Unité linéaire à porte gaussienne.
%   C = GELULAYER() applique X fois la probabilité qu'une gaussienne
%   centrée réduite soit inférieure à X. Le redresseur décide brutalement
%   de garder ou d'annuler ; celle-ci pondère continûment, ce qui la rend
%   dérivable partout et lui vaut sa place dans les transformeurs.
%
%   Exemple :
%      c = geluLayer('Name', 'gelu1');
%
%   Voir aussi RELULAYER, SWISHLAYER, SOFTPLUSLAYER.
    c = struct('type', 'gelu', 'nom', matlibre_couche_nom(varargin));
end
