function p = matlibre_normale_bivariee(h, k, rho)
%MATLIBRE_NORMALE_BIVARIEE Répartition normale à deux dimensions.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   MVNCDF s'en sert pour le cas de dimension deux, où la probabilité
%   s'écrit
%
%      P(h,k) = Phi(h)*Phi(k) + (1/2pi) * integrale de 0 a asin(rho)
%               de exp(-(h^2 - 2*h*k*sin t + k^2) / (2 cos^2 t)) dt
%
%   C'est la formule de Drezner et Wesolowsky. L'intégrale est évaluée
%   par une quadrature de Gauss-Legendre à vingt points, ce qui donne
%   une dizaine de chiffres exacts.
    if isnan(h) || isnan(k) || isnan(rho)
        p = NaN;
        return;
    end
    if rho > 1
        rho = 1;
    elseif rho < -1
        rho = -1;
    end
    if h == -Inf || k == -Inf
        p = 0;
        return;
    end
    if h == Inf && k == Inf
        p = 1;
        return;
    end
    if h == Inf
        p = normcdf(k);
        return;
    end
    if k == Inf
        p = normcdf(h);
        return;
    end
    if rho == 0
        p = normcdf(h) * normcdf(k);
        return;
    end
    if abs(rho) == 1
        if rho > 0
            p = normcdf(min(h, k));
        else
            p = max(0, normcdf(h) + normcdf(k) - 1);
        end
        return;
    end
    borne = asin(rho);
    [noeuds, poids] = matlibre_gauss_legendre(20);
    t = borne * (noeuds + 1) / 2;
    facteur = borne / 2;
    integrande = exp(-(h ^ 2 - 2 * h * k * sin(t) + k ^ 2) ./ (2 * cos(t) .^ 2));
    p = normcdf(h) * normcdf(k) + facteur * sum(poids .* integrande) / (2 * pi);
    p = max(0, min(1, p));
end
