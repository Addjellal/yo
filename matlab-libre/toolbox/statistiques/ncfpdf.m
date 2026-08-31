function d = ncfpdf(x, ddl1, ddl2, delta)
%NCFPDF Densité de la loi de Fisher décentrée.
%   D = NCFPDF(X,V1,V2,DELTA) rend la densité en X de la loi de Fisher
%   décentrée, à V1 et V2 degrés de liberté et de paramètre de
%   décentrage DELTA.
%
%   Comme la répartition, la densité s'écrit en mélange de Poisson de
%   densités de Fisher ordinaires, chacune à V1+2k degrés au numérateur
%   et mise à l'échelle en conséquence.
%
%   Exemples :
%      ncfpdf(2, 3, 20, 0)           % egale fpdf(2, 3, 20)
%      x = linspace(0, 8, 200);
%      plot(x, ncfpdf(x, 3, 20, 0), x, ncfpdf(x, 3, 20, 5));
%
%   Voir aussi NCFCDF, NCFINV, FPDF, NCX2PDF, NCTPDF.
    [x, ddl1, ddl2, delta] = statAjuster(x, ddl1, ddl2, delta);
    d = zeros(size(x));
    for i = 1:numel(x)
        d(i) = unePlace(x(i), ddl1(i), ddl2(i), delta(i));
    end
end

function d = unePlace(x, ddl1, ddl2, delta)
%UNEPLACE Le mélange de Poisson en un point.
    if isnan(x) || isnan(ddl1) || isnan(ddl2) || isnan(delta) || ...
       ddl1 <= 0 || ddl2 <= 0 || delta < 0
        d = NaN;
        return;
    end
    if x < 0
        d = 0;
        return;
    end
    if delta == 0
        d = fpdf(x, ddl1, ddl2);
        return;
    end
    demi = delta / 2;
    centre = max(0, floor(demi));
    logPoids = -demi + centre * log(demi) - gammaln(centre + 1);
    poids = exp(logPoids);
    echelle = @(k) ddl1 / (ddl1 + 2 * k);
    valeur = @(k) fpdf(x * echelle(k), ddl1 + 2 * k, ddl2) * echelle(k);
    d = poids * valeur(centre);
    w = poids;
    k = centre;
    for pas = 1:2000
        k = k + 1;
        w = w * demi / k;
        terme = w * valeur(k);
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
        terme = w * valeur(k);
        d = d + terme;
        if terme < 1e-16 * max(d, 1e-300) && w < 1e-15
            break;
        end
    end
    d = max(0, d);
end
