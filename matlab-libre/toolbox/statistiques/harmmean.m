function m = harmmean(x, dim)
%HARMMEAN Moyenne harmonique.
%   M = HARMMEAN(X) rend l'inverse de la moyenne des inverses : N divisé
%   par la somme des 1/X. Pour une matrice, une ligne de moyennes, une
%   par colonne. C'est la moyenne qui convient aux vitesses et aux débits :
%   parcourir la moitié du trajet à 30 et l'autre à 60 donne une vitesse
%   moyenne de 40, non de 45.
%
%   M = HARMMEAN(X,DIM) travaille le long de la dimension DIM.
%
%   Les valeurs doivent être strictement positives ; un zéro rend la
%   moyenne nulle, une valeur négative n'a pas de sens ici.
%
%   Exemples :
%      harmmean([30 60])                 % 40
%      harmmean([1 2 4])                 % 1.7143
%      harmmean([1 2; 3 4])              % [1.5 2.6667]
%
%   Voir aussi MEAN, GEOMEAN, TRIMMEAN, MEDIAN.
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
        error('stats:harmmean:BadData', ...
              'The harmonic mean needs nonnegative data.');
    end
    n = size(x, dim);
    if any(x(:) == 0)
        % Un seul zéro annule la moyenne : la somme des inverses est
        % infinie. On le dit sans passer par une division par zéro.
        m = sum(x, dim);
        m(:) = 0;
        return;
    end
    m = n ./ sum(1 ./ x, dim);
end
