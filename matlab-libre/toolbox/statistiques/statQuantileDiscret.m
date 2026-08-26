function x = statQuantileDiscret(repartition, p, depart, maximum)
%STATQUANTILEDISCRET Plus petit entier dont la répartition atteint P.
%   REPARTITION est une poignée de fonction, DEPART un point de départ
%   pour la marche, MAXIMUM la borne supérieure du support. Comme dans
%   MATLAB, le quantile d'une loi discrète est le plus petit entier X tel
%   que F(X) >= P ; la comparaison se fait sur la même fonction de
%   répartition que celle exportée, si bien que l'aller-retour est exact.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    x = max(0, floor(depart));
    if x > maximum, x = maximum; end
    if repartition(x) >= p
        while x > 0 && repartition(x - 1) >= p
            x = x - 1;
        end
    else
        while x < maximum && repartition(x) < p
            x = x + 1;
        end
    end
end
