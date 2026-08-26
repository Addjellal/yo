function x = tinv(p, nu)
%TINV Quantile de la loi de Student, par dichotomie sur TCDF.
    x = zeros(size(p));
    for k = 1:numel(p)
        cible = p(k);
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
            if tcdf(milieu, nu) < cible
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
