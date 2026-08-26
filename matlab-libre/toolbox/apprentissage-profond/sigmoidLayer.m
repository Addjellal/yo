function couche = sigmoidLayer(varargin)
%SIGMOIDLAYER Couche sigmoïde logistique.
    couche = struct('type', 'sigmoid', 'sorties', 0, 'W', [], 'b', [], ...
                    'entree', [], 'sortie', []);
end
