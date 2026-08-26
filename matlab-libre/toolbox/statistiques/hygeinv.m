function x = hygeinv(y, m, k, n)
%HYGEINV Quantile de la loi hypergéométrique.
    [y, m, k, n] = statAjuster(y, m, k, n);
    x = zeros(size(y));
    for indice = 1:numel(y)
        if ~(y(indice) >= 0 && y(indice) <= 1)
            x(indice) = NaN;
            continue
        end
        mm = m(indice); kk = k(indice); nn = n(indice);
        haut = min(kk, nn);
        x(indice) = statQuantileDiscret(@(t) hygecdf(t, mm, kk, nn), ...
                                        y(indice), 0, haut);
    end
end
