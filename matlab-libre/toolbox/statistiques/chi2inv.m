function x = chi2inv(p, v)
%CHI2INV Quantile du khi-deux, par dichotomie sur la répartition.
%   Les deux arguments se diffusent : un scalaire prend la taille de
%   l'autre.
%
%   Exemple :  chi2inv(0.95, 1)      % 3.8415
%              chi2inv(0.95, 1:3)    % 3.8415  5.9915  7.8147
    [p, v] = matlibre_diffuser_deux(p, v, 'chi2inv');
    x = zeros(size(p));
    for k = 1:numel(p)
        cible = p(k);
        ddl = v(k);
        if cible <= 0, x(k) = 0; continue, end
        if cible >= 1, x(k) = Inf; continue, end
        bas = 0;
        haut = max(10 * ddl, 10);
        while chi2cdf(haut, ddl) < cible && haut < 1e12
            haut = haut * 2;
        end
        for iteration = 1:200
            milieu = (bas + haut) / 2;
            if chi2cdf(milieu, ddl) < cible
                bas = milieu;
            else
                haut = milieu;
            end
        end
        x(k) = (bas + haut) / 2;
    end
end
