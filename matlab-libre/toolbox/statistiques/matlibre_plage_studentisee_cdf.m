function p = matlibre_plage_studentisee_cdf(q, K, ddl)
%MATLIBRE_PLAGE_STUDENTISEE_CDF Répartition de la plage studentisée.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Pour un écart type connu — DDL infini — la probabilité que l'étendue
%   de K normales centrées réduites reste sous Q vaut
%
%      K * integrale de phi(z) * [Phi(z) - Phi(z-q)]^(K-1) dz
%
%   Pour un DDL fini, on intègre en outre sur la loi de l'estimateur de
%   l'écart type, dont le carré suit un khi-deux réduit.
%
%   Les deux intégrales sont évaluées par quadrature de Gauss-Legendre,
%   sur un intervalle assez large pour que la queue négligée reste sous
%   le millionième.
    if q <= 0
        p = 0;
        return;
    end
    if isinf(ddl) || ddl <= 0 || ddl > 25000
        p = plageEcartConnu(q, K);
        return;
    end
    % Intégration sur s, l'écart type estimé : ddl*s^2 suit un khi-deux à
    % ddl degrés. La densité de s est concentrée autour de 1.
    [noeuds, poids] = matlibre_gauss_legendre(60);
    demiLargeur = 6 / sqrt(2 * ddl);
    bas = max(1e-6, 1 - demiLargeur);
    haut = 1 + demiLargeur;
    s = bas + (noeuds + 1) / 2 * (haut - bas);
    facteur = (haut - bas) / 2;
    % Densité de s : 2 * (ddl/2)^(ddl/2) / gamma(ddl/2) * s^(ddl-1) *
    % exp(-ddl*s^2/2), écrite par son logarithme pour ne pas déborder.
    logDensite = log(2) + (ddl / 2) * log(ddl / 2) - gammaln(ddl / 2) + ...
                 (ddl - 1) * log(s) - ddl * s .^ 2 / 2;
    densite = exp(logDensite);
    valeurs = zeros(size(s));
    for i = 1:numel(s)
        valeurs(i) = plageEcartConnu(q * s(i), K);
    end
    p = facteur * sum(poids .* densite .* valeurs);
    p = max(0, min(1, p));
end

function p = plageEcartConnu(q, K)
%PLAGEECARTCONNU La répartition quand l'écart type est connu.
    [noeuds, poids] = matlibre_gauss_legendre(80);
    bas = -8;
    haut = 8;
    z = bas + (noeuds + 1) / 2 * (haut - bas);
    facteur = (haut - bas) / 2;
    integrande = normpdf(z) .* (normcdf(z) - normcdf(z - q)) .^ (K - 1);
    p = K * facteur * sum(poids .* integrande);
    p = max(0, min(1, p));
end
