function q = matlibre_plage_studentisee(probabilite, K, ddl)
%MATLIBRE_PLAGE_STUDENTISEE Quantile de la plage studentisée.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   Q = MATLIBRE_PLAGE_STUDENTISEE(P,K,DDL) rend le quantile d'ordre P de
%   l'étendue de K variables normales, divisée par un écart type estimé à
%   DDL degrés de liberté. C'est la loi dont dépend le test de Tukey.
%
%   Le quantile est trouvé par dichotomie sur la répartition, elle-même
%   calculée par quadrature. Quarante bissections suffisent : elles
%   ramènent l'intervalle de départ, large de vingt, sous le
%   dix-milliardième.
    if K < 2
        q = 0;
        return;
    end
    bas = 0;
    haut = 20;
    for iteration = 1:40
        milieu = (bas + haut) / 2;
        if matlibre_plage_studentisee_cdf(milieu, K, ddl) < probabilite
            bas = milieu;
        else
            haut = milieu;
        end
    end
    q = (bas + haut) / 2;
end
