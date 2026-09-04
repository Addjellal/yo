function x = finv(p, d1, d2)
%FINV Quantile de la loi de Fisher, par dichotomie.
%   Les trois arguments se diffusent : un scalaire prend la taille des
%   autres.
%
%   Exemple :  finv(0.95, 2, 30)     % 3.3158
    [p, d1] = matlibre_diffuser_deux(p, d1, 'finv');
    [p, d2] = matlibre_diffuser_deux(p, d2, 'finv');
    [d1, d2] = matlibre_diffuser_deux(d1, d2, 'finv');
    x = zeros(size(p));
    for k = 1:numel(p)
        bas = 0;
        haut = 1e6;
        for iteration = 1:200
            milieu = (bas + haut) / 2;
            if fcdf(milieu, d1(k), d2(k)) < p(k)
                bas = milieu;
            else
                haut = milieu;
            end
        end
        x(k) = (bas + haut) / 2;
    end
end
