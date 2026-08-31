function p = nctcdf(x, ddl, delta)
%NCTCDF Répartition du Student décentré.
%   P = NCTCDF(X,V,DELTA) rend la probabilité qu'une variable de Student
%   décentrée à V degrés de liberté et de paramètre DELTA soit inférieure
%   à X.
%
%   Le Student décentré est la loi de (Z + DELTA) / racine(W/V), où Z est
%   normale centrée réduite et W un khi-deux à V degrés, indépendants.
%   C'est la loi de la statistique d'un test de Student quand l'hypothèse
%   nulle est fausse ; elle sert donc à calculer la puissance de ce test
%   et la taille d'échantillon nécessaire.
%
%   Contrairement au Student ordinaire, la loi n'est pas symétrique dès
%   que DELTA n'est pas nul.
%
%   Le calcul intègre la densité du khi-deux contre la répartition
%   normale, par quadrature de Gauss-Legendre sur un intervalle qui
%   couvre la masse à mieux que le millionième.
%
%   Exemples :
%      nctcdf(2, 10, 0)              % egale tcdf(2, 10)
%      nctcdf(2, 10, 1)              % plus petit : la loi est decalee
%      1 - nctcdf(tinv(0.95, 20), 20, 2)     % la puissance d'un test
%
%   Voir aussi TCDF, NCTPDF, NCTINV, NCX2CDF, NCFCDF, TTEST.
    [x, ddl, delta] = statAjuster(x, ddl, delta);
    p = zeros(size(x));
    for i = 1:numel(x)
        p(i) = unePlace(x(i), ddl(i), delta(i));
    end
end

function p = unePlace(x, ddl, delta)
%UNEPLACE La répartition en un point, par quadrature sur le khi-deux.
    if isnan(x) || isnan(ddl) || isnan(delta) || ddl <= 0
        p = NaN;
        return;
    end
    if delta == 0
        p = tcdf(x, ddl);
        return;
    end
    if isinf(x)
        p = double(x > 0);
        return;
    end
    % T = (Z + delta) / sqrt(W/v). En conditionnant sur s = sqrt(W/v),
    % P(T < x) = E[ Phi(x*s - delta) ], et s a pour densite celle qu'on
    % ecrit ci-dessous.
    [noeuds, poids] = matlibre_gauss_legendre(120);
    demiLargeur = 10 / sqrt(2 * ddl);
    bas = max(1e-8, 1 - demiLargeur);
    haut = 1 + demiLargeur;
    if ddl < 8
        % Peu de degres : la densite de s est large, il faut couvrir plus.
        bas = 1e-8;
        haut = 1 + 12 / sqrt(ddl);
    end
    s = bas + (noeuds + 1) / 2 * (haut - bas);
    facteur = (haut - bas) / 2;
    logDensite = log(2) + (ddl / 2) * log(ddl / 2) - gammaln(ddl / 2) + ...
                 (ddl - 1) * log(s) - ddl * s .^ 2 / 2;
    densite = exp(logDensite);
    p = facteur * sum(poids .* densite .* normcdf(x * s - delta));
    p = max(0, min(1, p));
end
