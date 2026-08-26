function resultat = ols(y, X, avecConstante)
%OLS Moindres carrés ordinaires, avec diagnostics.
    if nargin < 3
        avecConstante = true;
    end
    y = y(:);
    if avecConstante
        X = [ones(size(X, 1), 1), X];
    end
    b = X \ y;
    residus = y - X * b;
    n = numel(y);
    k = size(X, 2);
    sigma2 = sum(residus .^ 2) / max(n - k, 1);
    covariance = sigma2 * inv(X.' * X);
    ecarts = sqrt(diag(covariance));
    sct = sum((y - mean(y)) .^ 2);
    resultat = struct();
    resultat.beta = b;
    resultat.se = ecarts;
    resultat.t = b ./ ecarts;
    resultat.residus = residus;
    resultat.R2 = 1 - sum(residus .^ 2) / sct;
    resultat.R2ajuste = 1 - (1 - resultat.R2) * (n - 1) / max(n - k, 1);
    resultat.sigma2 = sigma2;
end
