function x = ncx2inv(p, ddl, delta)
%NCX2INV Quantile du khi-deux décentré.
%   X = NCX2INV(P,V,DELTA) rend la valeur X telle que NCX2CDF(X,V,DELTA)
%   vaille P.
%
%   L'inverse est cherché par dichotomie sur la répartition : elle est
%   strictement croissante, donc la bissection converge à coup sûr, sans
%   dépendre d'un point de départ.
%
%   Exemples :
%      ncx2inv(0.95, 2, 0)           % egale chi2inv(0.95, 2)
%      ncx2inv(0.95, 2, 3)           % plus grand : la loi est decalee
%      ncx2cdf(ncx2inv(0.7, 3, 2), 3, 2)     % rend 0.7
%
%   Voir aussi NCX2CDF, NCX2PDF, CHI2INV, NCTINV, NCFINV.
    [p, ddl, delta] = statAjuster(p, ddl, delta);
    x = zeros(size(p));
    for i = 1:numel(p)
        x(i) = matlibre_quantile_par_dichotomie(@(t) ncx2cdf(t, ddl(i), delta(i)), ...
                                                p(i), 0, ddl(i) + delta(i) + 1);
    end
end
