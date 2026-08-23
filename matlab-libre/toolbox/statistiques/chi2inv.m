function x = chi2inv(p, v)
%CHI2INV Quantile du khi-deux, par dichotomie sur la répartition.
%   Exemple :  chi2inv(0.95, 1)   % 3.8415
    x = zeros(size(p));
    for k = 1:numel(p)
        cible = p(k);
        if cible <= 0, x(k) = 0; continue, end
        if cible >= 1, x(k) = Inf; continue, end
        bas = 0;
        haut = max(10 * v, 10);
        while chi2cdf(haut, v) < cible && haut < 1e12
            haut = haut * 2;
        end
        for iteration = 1:200
            milieu = (bas + haut) / 2;
            if chi2cdf(milieu, v) < cible
                bas = milieu;
            else
                haut = milieu;
            end
        end
        x(k) = (bas + haut) / 2;
    end
end
