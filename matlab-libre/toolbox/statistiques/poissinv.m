function x = poissinv(p, lambda)
%POISSINV Quantile de la loi de Poisson.
%   Le plus petit entier X tel que POISSCDF(X,LAMBDA) >= P.
    [p, lambda] = statAjuster(p, lambda);
    x = zeros(size(p));
    for k = 1:numel(p)
        if ~(p(k) >= 0 && p(k) <= 1) || lambda(k) < 0
            x(k) = NaN;
            continue
        end
        if p(k) == 1, x(k) = Inf; continue, end
        l = lambda(k);
        % Départ par l'approximation normale, puis marche entière.
        depart = round(l + sqrt(max(l, 1)) * norminv(min(max(p(k), 1e-12), 1 - 1e-12)));
        x(k) = statQuantileDiscret(@(t) poisscdf(t, l), p(k), depart, 1e9);
    end
end
