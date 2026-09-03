function [indices, posterieures, densites] = clusterMelange(modele, X)
%CLUSTERMELANGE Attribution des points aux composantes d'un mélange.
%   Employer CLUSTER ou PREDICT ; cette fonction est le rouage qu'ils
%   appellent.
    X = double(X);
    n = size(X, 1);
    k = modele.NumComponents;
    d = modele.NumVariables;
    logDensites = zeros(n, k);
    for c = 1:k
        if modele.DiagonalCovariance
            S = diag(reshape(modele.Sigma(1, :, c), 1, d));
        else
            S = modele.Sigma(:, :, c);
        end
        logDensites(:, c) = log(max(modele.ComponentProportion(c), eps)) + ...
            log(max(mvnpdf(X, modele.mu(c, :), S), realmin));
    end
    maximum = max(logDensites, [], 2);
    exponentielles = exp(logDensites - repmat(maximum, 1, k));
    sommes = sum(exponentielles, 2);
    posterieures = exponentielles ./ repmat(sommes, 1, k);
    [~, indices] = max(posterieures, [], 2);
    densites = exp(maximum) .* sommes;
end
