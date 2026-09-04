function c = bilstmLayer(unites, varargin)
%BILSTMLAYER Couche récurrente à mémoire longue, dans les deux sens.
%   C = BILSTMLAYER(U) parcourt la séquence de gauche à droite et de
%   droite à gauche, puis met les deux sorties bout à bout : chaque
%   instant est donc décrit par ce qui le précède et par ce qui le suit.
%   La sortie a deux fois U composantes.
%
%   Le sens rétrograde interdit l'usage en temps réel — il faut la
%   séquence entière —, mais il vaut beaucoup là où on l'a : étiquetage de
%   texte, segmentation de signal.
%
%   Options et valeurs par défaut :
%     'OutputMode'   'sequence' ou 'last'
%     'Name'         le nom de la couche
%
%   Exemple :
%      c = bilstmLayer(16);
%
%   Voir aussi LSTMLAYER, GRULAYER, SEQUENCEINPUTLAYER.
    c = struct('type', 'bilstm', 'unites', unites, ...
               'sortieMode', matlibre_couche_mode(varargin), ...
               'W', [], 'R', [], 'b', [], 'Wr', [], 'Rr', [], 'br', [], ...
               'nom', matlibre_couche_nom(varargin));
end
