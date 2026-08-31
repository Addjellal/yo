function m = geomean(x, dim)
%GEOMEAN Moyenne géométrique.
%   M = GEOMEAN(X) rend la racine N-ième du produit des N éléments de X.
%   Pour une matrice, une ligne de moyennes, une par colonne. C'est la
%   moyenne qui convient aux taux de croissance et aux rapports : la
%   moyenne géométrique de 1.10 et 0.90 vaut 0.9950, non 1.
%
%   M = GEOMEAN(X,DIM) travaille le long de la dimension DIM.
%
%   Le calcul passe par les logarithmes, de sorte qu'un produit de mille
%   facteurs ne déborde pas. Les valeurs doivent être positives ou
%   nulles ; un zéro rend la moyenne nulle.
%
%   Exemples :
%      geomean([1 4 16])                 % 4
%      geomean([1.10 0.90])              % 0.99499
%      geomean([1 2; 3 4])               % [1.7321 2.8284]
%
%   Voir aussi MEAN, HARMMEAN, TRIMMEAN, MEDIAN.
    if nargin < 2
        if isvector(x)
            dim = find(size(x) > 1, 1);
            if isempty(dim)
                dim = 1;
            end
        else
            dim = 1;
        end
    end
    if any(x(:) < 0)
        error('stats:geomean:BadData', ...
              'The geometric mean needs nonnegative data.');
    end
    n = size(x, dim);
    m = exp(sum(log(x), dim) / n);
end
