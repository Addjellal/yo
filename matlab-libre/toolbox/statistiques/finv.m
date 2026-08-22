function x = finv(p, d1, d2)
%FINV Quantile de la loi de Fisher, par dichotomie.
    x = zeros(size(p));
    for k = 1:numel(p)
        bas = 0;
        haut = 1e6;
        for iteration = 1:200
            milieu = (bas + haut) / 2;
            if fcdf(milieu, d1, d2) < p(k)
                bas = milieu;
            else
                haut = milieu;
            end
        end
        x(k) = (bas + haut) / 2;
    end
end
