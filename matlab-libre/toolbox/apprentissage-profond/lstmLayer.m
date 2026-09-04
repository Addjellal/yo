function c = lstmLayer(unites, varargin)
%LSTMLAYER Couche récurrente à mémoire longue.
%   C = LSTMLAYER(U) parcourt la séquence en gardant deux états de U
%   composantes : une mémoire, qui traverse le temps presque sans être
%   modifiée, et une sortie. Trois portes — oubli, entrée, sortie —
%   décident à chaque instant de ce qu'on efface, de ce qu'on écrit et de
%   ce qu'on montre.
%
%   C'est la mémoire qui fait tout : parce qu'elle se transmet par une
%   addition et non par un produit de matrices, le gradient la remonte
%   sans s'évanouir, et le réseau peut relier des instants éloignés.
%
%   Options et valeurs par défaut :
%     'OutputMode'   'sequence', qui rend toute la suite des sorties, ou
%                    'last', qui n'en rend que la dernière — ce qu'il faut
%                    pour classer une séquence entière
%     'Name'         le nom de la couche
%
%   Exemple :
%      couches = {sequenceInputLayer(3), lstmLayer(16, 'OutputMode', 'last'), ...
%                 fullyConnectedLayer(2), softmaxLayer()};
%
%   Voir aussi GRULAYER, BILSTMLAYER, SEQUENCEINPUTLAYER.
    c = struct('type', 'lstm', 'unites', unites, ...
               'sortieMode', matlibre_couche_mode(varargin), ...
               'W', [], 'R', [], 'b', [], 'nom', matlibre_couche_nom(varargin));
end
