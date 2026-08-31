function p = ncx2cdf(x, ddl, delta)
%NCX2CDF Répartition du khi-deux décentré.
%   P = NCX2CDF(X,V,DELTA) rend la probabilité qu'une variable du
%   khi-deux à V degrés de liberté et de paramètre de décentrage DELTA
%   soit inférieure à X.
%
%   Le khi-deux décentré est la loi de la somme des carrés de V normales
%   d'écart type un dont les moyennes ne sont pas nulles ; DELTA est la
%   somme des carrés de ces moyennes. C'est la loi sous l'hypothèse
%   alternative des tests fondés sur le khi-deux, et c'est donc elle
%   qu'il faut pour calculer leur puissance.
%
%   Le calcul emploie le développement en mélange de Poisson :
%
%      P(X<x) = somme_k  exp(-delta/2) (delta/2)^k / k!  *  chi2cdf(x, v+2k)
%
%   Les termes sont sommés à partir du plus probable, vers la droite puis
%   vers la gauche, ce qui reste exact pour un DELTA de plusieurs
%   centaines.
%
%   Les arguments peuvent être des tableaux de même taille, ou des
%   scalaires.
%
%   Exemples :
%      ncx2cdf(5, 2, 0)              % 0.9179 : c'est chi2cdf(5,2)
%      ncx2cdf(5, 2, 3)              % plus petit : la loi est decalee
%      1 - ncx2cdf(chi2inv(0.95, 1), 1, 4)   % la puissance d'un test
%
%   Voir aussi CHI2CDF, NCTCDF, NCFCDF, NCX2PDF, NCX2INV.
    [x, ddl, delta] = statAjuster(x, ddl, delta);
    p = zeros(size(x));
    for i = 1:numel(x)
        p(i) = unePlace(x(i), ddl(i), delta(i));
    end
end

function p = unePlace(x, ddl, delta)
%UNEPLACE Le mélange de Poisson en un point.
    if isnan(x) || isnan(ddl) || isnan(delta) || ddl <= 0 || delta < 0
        p = NaN;
        return;
    end
    if x <= 0
        p = 0;
        return;
    end
    if delta == 0
        p = chi2cdf(x, ddl);
        return;
    end
    demi = delta / 2;
    centre = max(0, floor(demi));
    % Le poids du terme central, par son logarithme.
    logPoids = -demi + centre * log(demi) - gammaln(centre + 1);
    poids = exp(logPoids);
    p = poids * chi2cdf(x, ddl + 2 * centre);
    % Vers la droite.
    w = poids;
    k = centre;
    for pas = 1:2000
        k = k + 1;
        w = w * demi / k;
        terme = w * chi2cdf(x, ddl + 2 * k);
        p = p + terme;
        if terme < 1e-15 * max(p, 1e-300) && w < 1e-15
            break;
        end
    end
    % Vers la gauche.
    w = poids;
    k = centre;
    while k > 0
        w = w * k / demi;
        k = k - 1;
        terme = w * chi2cdf(x, ddl + 2 * k);
        p = p + terme;
        if terme < 1e-15 * max(p, 1e-300) && w < 1e-15
            break;
        end
    end
    p = max(0, min(1, p));
end
