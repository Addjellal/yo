function m = trimmean(x, pourcentage, dim)
%TRIMMEAN Moyenne élaguée.
%   M = TRIMMEAN(X,P) rend la moyenne de X après avoir écarté les P pour
%   cent des valeurs les plus extrêmes — la moitié en haut, la moitié en
%   bas. C'est un compromis entre la moyenne, sensible à une seule valeur
%   aberrante, et la médiane, qui n'emploie qu'un point.
%
%   Le nombre de valeurs retirées de chaque côté est FLOOR(N*P/200) :
%   TRIMMEAN(X,10) sur 100 points en retire cinq en haut et cinq en bas.
%   TRIMMEAN(X,0) est la moyenne ordinaire ; TRIMMEAN(X,100) tend vers
%   la médiane.
%
%   M = TRIMMEAN(X,P,DIM) travaille le long de la dimension DIM.
%
%   Exemples :
%      x = [1 2 3 4 5 6 7 8 9 1000];
%      mean(x)                           % 104.5, tirée par la dernière
%      trimmean(x, 20)                   % 5.5, insensible
%      trimmean(1:10, 0)                 % 5.5
%
%   Voir aussi MEAN, MEDIAN, GEOMEAN, HARMMEAN, PRCTILE.
    if pourcentage < 0 || pourcentage > 100
        error('stats:trimmean:BadPercent', ...
              'The trimming percentage must lie between 0 and 100.');
    end
    if nargin < 3
        if isvector(x)
            m = trimmeanColonne(x(:), pourcentage);
            return;
        end
        dim = 1;
    end
    if dim == 2
        m = zeros(size(x, 1), 1);
        for i = 1:size(x, 1)
            m(i) = trimmeanColonne(x(i, :)', pourcentage);
        end
    else
        m = zeros(1, size(x, 2));
        for j = 1:size(x, 2)
            m(j) = trimmeanColonne(x(:, j), pourcentage);
        end
    end
end

function m = trimmeanColonne(v, pourcentage)
%TRIMMEANCOLONNE La moyenne élaguée d'un seul vecteur.
    v = sort(v);
    n = numel(v);
    k = floor(n * pourcentage / 200);
    if 2 * k >= n
        m = median(v);
        return;
    end
    m = mean(v(k + 1:n - k));
end
