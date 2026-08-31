function [marge, p] = matlibre_marge_comparaison(ecart, erreur, alpha, correction, ...
                                                 K, ddl, nombrePaires)
%MATLIBRE_MARGE_COMPARAISON Demi-largeur et probabilité d'une comparaison.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   MULTCOMPARE s'en sert pour appliquer la correction de multiplicité
%   choisie sans répéter le calcul pour chaque paire.
    if erreur == 0
        marge = 0;
        p = double(ecart == 0);
        return;
    end
    switch correction
        case {'tukey-kramer', 'tukey', 'hsd'}
            % La plage studentisée : q(alpha,K,ddl) / racine(2).
            q = matlibre_plage_studentisee(1 - alpha, K, ddl);
            marge = q / sqrt(2) * erreur;
            t = abs(ecart) / erreur * sqrt(2);
            p = 1 - matlibre_plage_studentisee_cdf(t, K, ddl);
        case 'bonferroni'
            seuil = alpha / nombrePaires;
            if isinf(ddl)
                critique = norminv(1 - seuil / 2);
                p = min(1, nombrePaires * 2 * (1 - normcdf(abs(ecart) / erreur)));
            else
                critique = tinv(1 - seuil / 2, ddl);
                p = min(1, nombrePaires * 2 * (1 - tcdf(abs(ecart) / erreur, ddl)));
            end
            marge = critique * erreur;
        case {'lsd', 'none'}
            if isinf(ddl)
                critique = norminv(1 - alpha / 2);
                p = 2 * (1 - normcdf(abs(ecart) / erreur));
            else
                critique = tinv(1 - alpha / 2, ddl);
                p = 2 * (1 - tcdf(abs(ecart) / erreur, ddl));
            end
            marge = critique * erreur;
        otherwise
            error('stats:multcompare:BadCtype', ...
                  'Unknown correction ''%s''.', correction);
    end
end
