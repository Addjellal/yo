function d = ncx2pdf(x, ddl, delta)
%NCX2PDF Densité du khi-deux décentré.
%   D = NCX2PDF(X,V,DELTA) rend la densité en X de la loi du khi-deux à V
%   degrés de liberté et de paramètre de décentrage DELTA.
%
%   Comme la répartition, la densité s'écrit en mélange de Poisson :
%
%      f(x) = somme_k  exp(-delta/2) (delta/2)^k / k!  *  chi2pdf(x, v+2k)
%
%   Quand DELTA vaut zéro, on retrouve exactement CHI2PDF.
%
%   Exemples :
%      ncx2pdf(3, 2, 0)              % egale chi2pdf(3, 2)
%      ncx2pdf(3, 2, 4)
%      x = linspace(0, 25, 200);
%      plot(x, ncx2pdf(x, 4, 0), x, ncx2pdf(x, 4, 6));
%
%   Voir aussi NCX2CDF, NCX2INV, CHI2PDF, NCTPDF, NCFPDF.
    [x, ddl, delta] = statAjuster(x, ddl, delta);
    d = zeros(size(x));
    for i = 1:numel(x)
        d(i) = unePlace(x(i), ddl(i), delta(i));
    end
end

function d = unePlace(x, ddl, delta)
%UNEPLACE Le mélange de Poisson en un point.
    if isnan(x) || isnan(ddl) || isnan(delta) || ddl <= 0 || delta < 0
        d = NaN;
        return;
    end
    if x < 0
        d = 0;
        return;
    end
    if delta == 0
        d = chi2pdf(x, ddl);
        return;
    end
    demi = delta / 2;
    centre = max(0, floor(demi));
    logPoids = -demi + centre * log(demi) - gammaln(centre + 1);
    poids = exp(logPoids);
    d = poids * chi2pdf(x, ddl + 2 * centre);
    w = poids;
    k = centre;
    for pas = 1:2000
        k = k + 1;
        w = w * demi / k;
        terme = w * chi2pdf(x, ddl + 2 * k);
        d = d + terme;
        if terme < 1e-16 * max(d, 1e-300) && w < 1e-15
            break;
        end
    end
    w = poids;
    k = centre;
    while k > 0
        w = w * k / demi;
        k = k - 1;
        terme = w * chi2pdf(x, ddl + 2 * k);
        d = d + terme;
        if terme < 1e-16 * max(d, 1e-300) && w < 1e-15
            break;
        end
    end
    d = max(0, d);
end
