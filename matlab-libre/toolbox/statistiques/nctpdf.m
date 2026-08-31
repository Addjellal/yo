function d = nctpdf(x, ddl, delta)
%NCTPDF Densité du Student décentré.
%   D = NCTPDF(X,V,DELTA) rend la densité en X de la loi de Student
%   décentrée à V degrés de liberté et de paramètre DELTA.
%
%   La densité s'obtient de la même façon que la répartition, en
%   conditionnant sur l'estimateur de l'écart type :
%
%      f(x) = E[ s * phi(x*s - delta) ]
%
%   où s est la racine d'un khi-deux réduit à V degrés.
%
%   Quand DELTA vaut zéro, on retrouve TPDF.
%
%   Exemples :
%      nctpdf(0, 10, 0)              % egale tpdf(0, 10)
%      x = linspace(-4, 8, 200);
%      plot(x, nctpdf(x, 10, 0), x, nctpdf(x, 10, 2));
%
%   Voir aussi NCTCDF, NCTINV, TPDF, NCX2PDF, NCFPDF.
    [x, ddl, delta] = statAjuster(x, ddl, delta);
    d = zeros(size(x));
    for i = 1:numel(x)
        d(i) = unePlace(x(i), ddl(i), delta(i));
    end
end

function d = unePlace(x, ddl, delta)
%UNEPLACE La densité en un point, par quadrature sur le khi-deux.
    if isnan(x) || isnan(ddl) || isnan(delta) || ddl <= 0
        d = NaN;
        return;
    end
    if delta == 0
        d = tpdf(x, ddl);
        return;
    end
    if isinf(x)
        d = 0;
        return;
    end
    [noeuds, poids] = matlibre_gauss_legendre(120);
    if ddl < 8
        bas = 1e-8;
        haut = 1 + 12 / sqrt(ddl);
    else
        demiLargeur = 10 / sqrt(2 * ddl);
        bas = max(1e-8, 1 - demiLargeur);
        haut = 1 + demiLargeur;
    end
    s = bas + (noeuds + 1) / 2 * (haut - bas);
    facteur = (haut - bas) / 2;
    logDensite = log(2) + (ddl / 2) * log(ddl / 2) - gammaln(ddl / 2) + ...
                 (ddl - 1) * log(s) - ddl * s .^ 2 / 2;
    densite = exp(logDensite);
    d = facteur * sum(poids .* densite .* s .* normpdf(x * s - delta));
    d = max(0, d);
end
