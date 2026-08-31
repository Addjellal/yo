function [D, indices] = pdist2(X, Y, metrique, varargin)
%PDIST2 Distances entre deux jeux d'observations.
%   D = PDIST2(X,Y) rend la matrice des distances euclidiennes entre les
%   lignes de X et celles de Y : D(i,j) est la distance de X(i,:) à
%   Y(j,:). Elle a autant de lignes que X et autant de colonnes que Y.
%
%   D = PDIST2(X,Y,METRIQUE) choisit la distance, parmi les mêmes que
%   PDIST : 'euclidean', 'seuclidean', 'cityblock', 'chebychev',
%   'minkowski', 'cosine', 'correlation', 'hamming', 'jaccard',
%   'spearman'. PDIST2(X,Y,'minkowski',P) fixe l'exposant.
%
%   [D,I] = PDIST2(X,Y,METRIQUE,'Smallest',K) ne rend que les K plus
%   petites distances de chaque colonne, triées, et les indices des
%   lignes de X où elles ont été trouvées. 'Largest' fait l'inverse.
%   C'est la forme qui sert à chercher les plus proches voisins sans
%   construire toute la matrice de distances en mémoire utile.
%
%   Exemples :
%      X = [0 0; 3 4; 1 1];
%      Y = [0 0; 1 1];
%      pdist2(X, Y)                        % 3 x 2
%      [d, i] = pdist2(X, Y, 'euclidean', 'Smallest', 1)
%      % d = [0 0], i = [1 3] : chaque ligne de Y a sa jumelle dans X,
%      % a la distance nulle, et I dit laquelle
%
%   Voir aussi PDIST, SQUAREFORM, KNNSEARCH, MAHAL, KMEANS.
    if nargin < 3 || isempty(metrique)
        metrique = 'euclidean';
    end
    parametre = 2;
    plusPetites = 0;
    plusGrandes = 0;
    k = 1;
    if numel(varargin) >= 1 && isnumeric(varargin{1})
        parametre = varargin{1};
        k = 2;
    end
    while k + 1 <= numel(varargin)
        nomOption = lower(char(varargin{k}));
        if strcmp(nomOption, 'smallest')
            plusPetites = varargin{k + 1};
        elseif strcmp(nomOption, 'largest')
            plusGrandes = varargin{k + 1};
        else
            error('stats:pdist2:BadOption', 'Unknown option ''%s''.', nomOption);
        end
        k = k + 2;
    end
    if size(X, 2) ~= size(Y, 2)
        error('stats:pdist2:InputSizeMismatch', ...
              'X and Y must have the same number of columns.');
    end
    nom = lower(char(metrique));
    echelle = [];
    if strcmp(nom, 'seuclidean')
        echelle = std([X; Y], 0, 1);
        echelle(echelle == 0) = 1;
    end
    if strcmp(nom, 'spearman')
        X = tiedrank(X);
        Y = tiedrank(Y);
        nom = 'correlation';
    end
    D = zeros(size(X, 1), size(Y, 1));
    for i = 1:size(X, 1)
        for j = 1:size(Y, 1)
            D(i, j) = matlibre_distance(X(i, :), Y(j, :), nom, parametre, echelle);
        end
    end
    indices = [];
    if plusPetites > 0 || plusGrandes > 0
        combien = max(plusPetites, plusGrandes);
        combien = min(combien, size(D, 1));
        garde = zeros(combien, size(D, 2));
        indices = zeros(combien, size(D, 2));
        for j = 1:size(D, 2)
            if plusGrandes > 0
                [triees, ordre] = sort(D(:, j), 'descend');
            else
                [triees, ordre] = sort(D(:, j), 'ascend');
            end
            garde(:, j) = triees(1:combien);
            indices(:, j) = ordre(1:combien);
        end
        D = garde;
    end
end
