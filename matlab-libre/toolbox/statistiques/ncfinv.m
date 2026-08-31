function x = ncfinv(p, ddl1, ddl2, delta)
%NCFINV Quantile de la loi de Fisher décentrée.
%   X = NCFINV(P,V1,V2,DELTA) rend la valeur X telle que
%   NCFCDF(X,V1,V2,DELTA) vaille P.
%
%   L'inverse est cherché par dichotomie sur la répartition.
%
%   Exemples :
%      ncfinv(0.95, 3, 20, 0)        % egale finv(0.95, 3, 20)
%      ncfinv(0.95, 3, 20, 5)
%      ncfcdf(ncfinv(0.6, 2, 12, 3), 2, 12, 3)    % rend 0.6
%
%   Voir aussi NCFCDF, NCFPDF, FINV, NCX2INV, NCTINV.
    [p, ddl1, ddl2, delta] = statAjuster(p, ddl1, ddl2, delta);
    x = zeros(size(p));
    for i = 1:numel(p)
        x(i) = matlibre_quantile_par_dichotomie( ...
            @(t) ncfcdf(t, ddl1(i), ddl2(i), delta(i)), p(i), 0, ...
            1 + delta(i) / max(ddl1(i), 1));
    end
end
