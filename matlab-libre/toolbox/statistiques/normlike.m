function nlogL = normlike(params, data)
%NORMLIKE Opposé de la log-vraisemblance d'une loi normale.
%   PARAMS vaut [MU SIGMA].
%
%   Exemple :
%      rng(1);
%      x = normrnd(5, 2, 500, 1);
%      normlike([5 2], x) < normlike([0 1], x)     % vrai
    mu = params(1);
    sigma = params(2);
    x = double(data(:));
    if sigma <= 0
        nlogL = Inf;
        return
    end
    n = numel(x);
    nlogL = n * log(sigma) + n * log(2 * pi) / 2 + sum((x - mu) .^ 2) / (2 * sigma ^ 2);
end
