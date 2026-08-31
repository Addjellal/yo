function x = matlibre_quantile_par_dichotomie(repartition, p, minimum, echelle)
%MATLIBRE_QUANTILE_PAR_DICHOTOMIE Inverse une répartition croissante.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   Les lois décentrées n'ont pas de quantile en forme close ; on inverse
%   donc leur répartition. La bissection y suffit et ne peut pas
%   diverger, la répartition étant croissante.
%
%   MINIMUM est la borne inférieure du support — 0 pour un khi-deux,
%   -Inf pour un Student décentré. ECHELLE donne l'ordre de grandeur par
%   lequel commencer à chercher la borne supérieure.
    if isnan(p) || p < 0 || p > 1
        x = NaN;
        return;
    end
    if p == 0
        x = minimum;
        return;
    end
    if p == 1
        x = Inf;
        return;
    end
    if isinf(minimum)
        bas = -max(1, echelle);
        while repartition(bas) > p && bas > -1e12
            bas = bas * 2;
        end
    else
        bas = minimum;
    end
    haut = max(abs(echelle), 1);
    for essai = 1:200
        if repartition(haut) >= p
            break;
        end
        haut = haut * 2;
        if haut > 1e12
            break;
        end
    end
    for iteration = 1:200
        milieu = (bas + haut) / 2;
        if repartition(milieu) < p
            bas = milieu;
        else
            haut = milieu;
        end
        if haut - bas <= 1e-12 * max(1, abs(haut))
            break;
        end
    end
    x = (bas + haut) / 2;
end
