function [X, composantes] = tirerMelange(modele, n, varargin)
%TIRERMELANGE Tirage dans un mélange gaussien.
%   Employer RANDOM ; cette fonction est le rouage qu'il appelle.
%
%   Exemple :
%      rng(1);
%      m = fitgmdist([randn(200, 1); randn(200, 1) + 8], 2);
%      [x, composantes] = tirerMelange(m, 500);
%      all(composantes >= 1 & composantes <= 2)
%
%   Voir aussi FITGMDIST, RANDOM, CLUSTERMELANGE.
    if nargin < 2 || isempty(n)
        n = 1;
    end
    n = round(n);
    k = modele.NumComponents;
    d = modele.NumVariables;
    cumul = cumsum(modele.ComponentProportion);
    composantes = zeros(n, 1);
    X = zeros(n, d);
    for i = 1:n
        c = find(cumul >= rand(), 1);
        if isempty(c)
            c = k;
        end
        composantes(i) = c;
        if modele.DiagonalCovariance
            S = diag(reshape(modele.Sigma(1, :, c), 1, d));
        else
            S = modele.Sigma(:, :, c);
        end
        X(i, :) = mvnrnd(modele.mu(c, :), S, 1);
    end
end
