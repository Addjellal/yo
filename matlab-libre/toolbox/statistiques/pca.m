function [coefficients, scores, valeurs, expliquee] = pca(X)
%PCA Analyse en composantes principales.
%   [C,S,L] = PCA(X) centre les colonnes de X, puis rend les vecteurs
%   propres de la covariance (C), les coordonnées des individus (S) et les
%   valeurs propres (L), triés par variance décroissante.
    [n, p] = size(X);
    mu = mean(X);
    Xc = X - repmat(mu, n, 1);
    C = (Xc' * Xc) / max(n - 1, 1);
    [V, D] = eig(C);
    valeurs = diag(D);
    [valeurs, ordre] = sort(valeurs, 'descend');
    coefficients = V(:, ordre);
    scores = Xc * coefficients;
    total = sum(valeurs);
    if total == 0
        expliquee = zeros(size(valeurs));
    else
        expliquee = 100 * valeurs / total;
    end
end
