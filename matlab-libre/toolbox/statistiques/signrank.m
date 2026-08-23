function [p, h, statistiques] = signrank(x, y, alpha)
%SIGNRANK Test des rangs signés de Wilcoxon, sur échantillons appariés.
%   P = SIGNRANK(X) teste la médiane nulle ; SIGNRANK(X,Y) teste la
%   médiane de X-Y.
    if nargin < 2 || isempty(y), y = zeros(size(x)); end
    if nargin < 3, alpha = 0.05; end
    d = x(:) - y(:);
    d = d(d ~= 0);
    n = numel(d);
    if n == 0
        p = 1; h = false; statistiques = struct('signedrank', 0, 'zval', 0);
        return
    end
    [~, ordre] = sort(abs(d));
    rangs = zeros(n, 1);
    rangs(ordre) = 1:n;
    W = sum(rangs(d > 0));
    moyenne = n * (n + 1) / 4;
    variance = n * (n + 1) * (2 * n + 1) / 24;
    z = (W - moyenne - 0.5 * sign(W - moyenne)) / sqrt(variance);
    p = 2 * (1 - normcdf(abs(z)));
    h = p < alpha;
    statistiques = struct('signedrank', W, 'zval', z);
end
