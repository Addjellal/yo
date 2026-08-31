function x = nctinv(p, ddl, delta)
%NCTINV Quantile du Student décentré.
%   X = NCTINV(P,V,DELTA) rend la valeur X telle que NCTCDF(X,V,DELTA)
%   vaille P.
%
%   Comme le support s'étend de moins l'infini à plus l'infini, la
%   recherche commence par élargir un intervalle de part et d'autre,
%   puis procède par dichotomie.
%
%   Exemples :
%      nctinv(0.95, 10, 0)           % egale tinv(0.95, 10)
%      nctinv(0.95, 10, 2)
%      nctcdf(nctinv(0.3, 8, 1), 8, 1)       % rend 0.3
%
%   Voir aussi NCTCDF, NCTPDF, TINV, NCX2INV, NCFINV.
    [p, ddl, delta] = statAjuster(p, ddl, delta);
    x = zeros(size(p));
    for i = 1:numel(p)
        x(i) = matlibre_quantile_par_dichotomie(@(t) nctcdf(t, ddl(i), delta(i)), ...
                                                p(i), -Inf, abs(delta(i)) + 5);
    end
end
