function y = layernorm(x, decalage, echelle, varargin)
%LAYERNORM Normalisation par couche.
%   Y = LAYERNORM(X,DECALAGE,ECHELLE) centre et réduit chaque observation
%   sur toutes ses dimensions sauf celle du lot : contrairement à la
%   normalisation par lot, le résultat d'une observation ne dépend
%   d'aucune autre. C'est ce qui la rend utilisable quand le lot est
%   petit, ou quand les observations n'ont pas la même longueur.
%
%   Options et valeurs par défaut :
%     'Epsilon'              1e-5
%     'OperationDimension'   'auto' — toutes les dimensions sauf le lot —
%                            ou 'channel-only'
%     'DataFormat'           le format, quand X n'en porte pas
%
%   Exemple :
%      x = dlarray(randn(6, 8), 'CB');
%      y = layernorm(x, 0, 1);
%      round(mean(extractdata(y), 1), 10)      % des zéros
%
%   Voir aussi BATCHNORM, GROUPNORM, LAYERNORMALIZATIONLAYER.
    epsilon = 1e-5;
    format = '';
    portee = 'auto';
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'epsilon',            epsilon = double(varargin{k + 1});
            case 'dataformat',         format = upper(char(varargin{k + 1}));
            case 'operationdimension', portee = lower(char(varargin{k + 1}));
            otherwise
                error('nnet:layernorm:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    [canal, lot, nombre] = matlibre_dl_axe_canal(x, format);
    if strcmp(portee, 'channel-only')
        dimensions = canal;
    else
        dimensions = setdiff(1:nombre, lot);
    end
    forme = ones(1, nombre);
    forme(canal) = numel(matlibre_dl_valeur(echelle));
    y = matlibre_dl_normaliser(x, dimensions, reshape(decalage, forme), ...
                               reshape(echelle, forme), epsilon);
end
