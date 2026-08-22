function [etiquettes, centres, inerties] = kmeans(X, k, varargin)
%KMEANS Partition en k classes par l'algorithme de Lloyd.
%   [IDX,C] = KMEANS(X,K) partitionne les lignes de X en K classes.
%   Options : 'MaxIter' (100), 'Start' (matrice des centres initiaux).
    maxIterations = 100;
    centres = [];
    for i = 1:2:numel(varargin)-1
        switch lower(char(varargin{i}))
            case 'maxiter'
                maxIterations = varargin{i+1};
            case 'start'
                centres = varargin{i+1};
        end
    end
    [n, p] = size(X);
    if isempty(centres)
        ordre = randperm(n);
        centres = X(ordre(1:k), :);
    end
    etiquettes = ones(n, 1);
    for iteration = 1:maxIterations
        changement = false;
        for i = 1:n
            meilleure = 1;
            meilleureDistance = inf;
            for c = 1:k
                d = sum((X(i, :) - centres(c, :)) .^ 2);
                if d < meilleureDistance
                    meilleureDistance = d;
                    meilleure = c;
                end
            end
            if etiquettes(i) ~= meilleure
                etiquettes(i) = meilleure;
                changement = true;
            end
        end
        for c = 1:k
            membres = X(etiquettes == c, :);
            if ~isempty(membres)
                centres(c, :) = mean(membres, 1);
            end
        end
        if ~changement
            break;
        end
    end
    inerties = zeros(k, 1);
    for c = 1:k
        membres = X(etiquettes == c, :);
        for i = 1:size(membres, 1)
            inerties(c) = inerties(c) + sum((membres(i, :) - centres(c, :)) .^ 2);
        end
    end
end
