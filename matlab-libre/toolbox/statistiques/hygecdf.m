function p = hygecdf(x, m, k, n)
%HYGECDF Répartition de la loi hypergéométrique.
%   Le support est fini : la somme directe des probabilités est exacte.
%
%   Exemple :
%      hygecdf(5, 50, 10, 5)       % 1 : on ne peut pas tirer plus de cinq marques
%
%   Voir aussi HYGEPDF, HYGEINV, HYGERND, HYGESTAT, PDF, CDF.
    [x, m, k, n] = statAjuster(x, m, k, n);
    p = zeros(size(x));
    for indice = 1:numel(x)
        borne = floor(x(indice));
        haut = min(k(indice), n(indice));
        if borne >= haut
            p(indice) = 1;
        elseif borne < 0
            p(indice) = 0;
        else
            somme = 0;
            for j = max(0, n(indice) - (m(indice) - k(indice))):borne
                somme = somme + hygepdf(j, m(indice), k(indice), n(indice));
            end
            p(indice) = somme;
        end
    end
    p(isnan(hygepdf(0, m, k, n)) & ~(0 < max(0, n - (m - k)))) = NaN;
end
