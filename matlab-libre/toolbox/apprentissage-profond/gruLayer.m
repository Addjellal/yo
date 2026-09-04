function c = gruLayer(unites, varargin)
%GRULAYER Couche récurrente à portes.
%   C = GRULAYER(U) tient un seul état de U composantes, gouverné par deux
%   portes : l'une décide de ce qu'on oublie, l'autre de la part de neuf
%   qu'on écrit. Elle fait à peu près ce que fait une mémoire longue, avec
%   un tiers de poids en moins et sans état de cellule séparé.
%
%   Options et valeurs par défaut :
%     'OutputMode'   'sequence' ou 'last'
%     'Name'         le nom de la couche
%
%   Exemple :
%      c = gruLayer(32, 'OutputMode', 'last');
%
%   Voir aussi LSTMLAYER, BILSTMLAYER, SEQUENCEINPUTLAYER.
    c = struct('type', 'gru', 'unites', unites, ...
               'sortieMode', matlibre_couche_mode(varargin), ...
               'W', [], 'R', [], 'b', [], 'nom', matlibre_couche_nom(varargin));
end
