function [h, p, ksstat, cv] = kstest(x, alpha)
%KSTEST Test de Kolmogorov-Smirnov contre la loi normale centrée réduite.
%   [H,P,D] = KSTEST(X) compare la répartition empirique de X à celle de
%   la loi normale standard. H vaut 1 quand l'hypothèse est rejetée.
%
%   La p-valeur vient de la série de Kolmogorov, tronquée à cent termes.
    if nargin < 2 || isempty(alpha), alpha = 0.05; end
    x = sort(x(:));
    n = numel(x);
    empirique = (1:n)' / n;
    empiriqueAvant = (0:n-1)' / n;
    theorique = normcdf(x);
    ksstat = max(max(abs(empirique - theorique)), max(abs(theorique - empiriqueAvant)));
    lambda = (sqrt(n) + 0.12 + 0.11 / sqrt(n)) * ksstat;
    p = 0;
    for k = 1:100
        p = p + 2 * (-1)^(k - 1) * exp(-2 * k^2 * lambda^2);
    end
    p = min(max(p, 0), 1);
    h = p < alpha;
    cv = sqrt(-0.5 * log(alpha / 2)) / sqrt(n);
end
