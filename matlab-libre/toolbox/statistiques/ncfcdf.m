function p = ncfcdf(x, ddl1, ddl2, delta)
%NCFCDF Répartition de la loi de Fisher décentrée.
%   P = NCFCDF(X,V1,V2,DELTA) rend la probabilité qu'une variable de
%   Fisher décentrée, à V1 et V2 degrés de liberté et de paramètre de
%   décentrage DELTA, soit inférieure à X.
%
%   C'est la loi du rapport (W1/V1)/(W2/V2) où W1 est un khi-deux
%   décentré à V1 degrés et de paramètre DELTA, W2 un khi-deux ordinaire
%   à V2 degrés. C'est la loi de la statistique d'une analyse de variance
%   quand les moyennes ne sont pas égales : elle donne donc la puissance
%   du test et la taille d'échantillon qu'il faudrait.
%
%   Le calcul emploie le mélange de Poisson, chaque terme se ramenant à
%   une répartition de Fisher ordinaire.
%
%   Exemples :
%      ncfcdf(3, 2, 10, 0)           % egale fcdf(3, 2, 10)
%      ncfcdf(3, 2, 10, 5)           % plus petit
%      1 - ncfcdf(finv(0.95, 2, 27), 2, 27, 6)    % la puissance d'une
%                                                 % analyse de variance
%
%   Voir aussi FCDF, NCFPDF, NCFINV, NCX2CDF, NCTCDF, ANOVA1.
    [x, ddl1, ddl2, delta] = statAjuster(x, ddl1, ddl2, delta);
    p = zeros(size(x));
    for i = 1:numel(x)
        p(i) = unePlace(x(i), ddl1(i), ddl2(i), delta(i));
    end
end

function p = unePlace(x, ddl1, ddl2, delta)
%UNEPLACE Le mélange de Poisson en un point.
    if isnan(x) || isnan(ddl1) || isnan(ddl2) || isnan(delta) || ...
       ddl1 <= 0 || ddl2 <= 0 || delta < 0
        p = NaN;
        return;
    end
    if x <= 0
        p = 0;
        return;
    end
    if delta == 0
        p = fcdf(x, ddl1, ddl2);
        return;
    end
    demi = delta / 2;
    centre = max(0, floor(demi));
    logPoids = -demi + centre * log(demi) - gammaln(centre + 1);
    poids = exp(logPoids);
    % Le k-ieme terme porte sur un Fisher a ddl1+2k degres, dont
    % l'argument est mis a l'echelle en consequence.
    valeur = @(k) fcdf(x * ddl1 / (ddl1 + 2 * k), ddl1 + 2 * k, ddl2);
    p = poids * valeur(centre);
    w = poids;
    k = centre;
    for pas = 1:2000
        k = k + 1;
        w = w * demi / k;
        terme = w * valeur(k);
        p = p + terme;
        if terme < 1e-15 * max(p, 1e-300) && w < 1e-15
            break;
        end
    end
    w = poids;
    k = centre;
    while k > 0
        w = w * k / demi;
        k = k - 1;
        terme = w * valeur(k);
        p = p + terme;
        if terme < 1e-15 * max(p, 1e-300) && w < 1e-15
            break;
        end
    end
    p = max(0, min(1, p));
end
