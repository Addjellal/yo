function p = matlibre_kolmogorov_queue(lambda)
%MATLIBRE_KOLMOGOROV_QUEUE Queue de la loi de Kolmogorov.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   P = MATLIBRE_KOLMOGOROV_QUEUE(L) rend
%
%      Q(L) = 2 * somme_{k>=1} (-1)^(k-1) exp(-2 k^2 L^2)
%
%   la probabilité que la statistique de Kolmogorov-Smirnov normalisée
%   dépasse L. C'est la limite quand l'effectif grandit ; elle est déjà
%   bonne à quelques dizaines d'observations.
    if lambda <= 0
        p = 1;
        return;
    end
    if lambda > 7.5
        p = 0;
        return;
    end
    p = 0;
    for k = 1:200
        terme = 2 * (-1) ^ (k - 1) * exp(-2 * k ^ 2 * lambda ^ 2);
        p = p + terme;
        if abs(terme) < 1e-14
            break;
        end
    end
    p = max(0, min(1, p));
end
