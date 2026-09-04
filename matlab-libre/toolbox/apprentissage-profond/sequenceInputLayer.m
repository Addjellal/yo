function c = sequenceInputLayer(taille, varargin)
%SEQUENCEINPUTLAYER Entrée d'un réseau récurrent.
%   C = SEQUENCEINPUTLAYER(T) déclare des séquences de T composantes par
%   pas de temps. Les données se rangent en canaux-observations-temps :
%   une matrice par observation, une colonne par instant.
%
%   Option : 'Normalization' ('none' par défaut, ou 'zscore').
%
%   Exemple :
%      c = sequenceInputLayer(3);
%
%   Voir aussi LSTMLAYER, GRULAYER, BILSTMLAYER, FEATUREINPUTLAYER.
    normalisation = 'none';
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'normalization')
            normalisation = lower(char(varargin{k + 1}));
        end
    end
    c = struct('type', 'sequenceinput', 'taille', taille, ...
               'normalisation', normalisation, 'nom', matlibre_couche_nom(varargin));
end
