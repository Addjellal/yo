function couche = softmaxLayer(varargin)
%SOFTMAXLAYER Couche softmax : sorties positives de somme 1.
    couche = struct('type', 'softmax', 'sorties', 0, 'W', [], 'b', [], ...
                    'entree', [], 'sortie', []);
end
