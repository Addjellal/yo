function couche = fullyConnectedLayer(sorties, varargin)
%FULLYCONNECTEDLAYER Couche entièrement connectée de N sorties.
%   Les poids sont initialisés par la règle de Glorot une fois la taille
%   d'entrée connue, au premier appel de TRAINNETWORK.
%
%   Exemple :
%      c = fullyConnectedLayer(5);
%      c.sorties                   % 5
%
%   Voir aussi FULLYCONNECT, RELULAYER, SOFTMAXLAYER.
    couche = struct('type', 'fc', 'sorties', sorties, 'W', [], 'b', [], ...
                    'entree', [], 'sortie', [], ...
                    'nom', matlibre_couche_nom(varargin));
end
