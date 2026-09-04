function x = tinv(p, nu)
%TINV Quantile de la loi de Student, par dichotomie sur TCDF.
%   Les deux arguments se diffusent : un scalaire prend la taille de
%   l'autre.
%
%   Exemple :  tinv(0.975, 10)       % 2.2281
    [p, nu] = matlibre_diffuser_deux(p, nu, 'tinv');
    x = zeros(size(p));
    for k = 1:numel(p)
        cible = p(k);
        ddl = nu(k);
        if cible <= 0
            x(k) = -inf;
            continue;
        end
        if cible >= 1
            x(k) = inf;
            continue;
        end
        bas = -1e6;
        haut = 1e6;
        for iteration = 1:200
            milieu = (bas + haut) / 2;
            if tcdf(milieu, ddl) < cible
                bas = milieu;
            else
                haut = milieu;
            end
            if haut - bas < 1e-12 * max(1, abs(haut))
                break;
            end
        end
        x(k) = (bas + haut) / 2;
    end
end
