function couche = fullyConnectedLayer(sorties, varargin)
%FULLYCONNECTEDLAYER Couche entièrement connectée de N sorties.
%   Les poids sont initialisés par la règle de Glorot une fois la taille
%   d'entrée connue, au premier appel de TRAINNETWORK.
    couche = struct('type', 'fc', 'sorties', sorties, 'W', [], 'b', [], ...
                    'entree', [], 'sortie', []);
end
