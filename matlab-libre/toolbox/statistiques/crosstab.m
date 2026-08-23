function [table_, khi2, p, etiquettes] = crosstab(x, y)
%CROSSTAB Table de contingence de deux variables discrètes.
%   [T,CHI2,P] = CROSSTAB(X,Y) rend la table des effectifs, la statistique
%   du khi-deux d'indépendance et sa p-valeur.
%
%   Exemple :
%      crosstab([1 1 2 2], [1 2 1 2])   % [1 1; 1 1]
    x = x(:);
    y = y(:);
    vx = unique(x);
    vy = unique(y);
    table_ = zeros(numel(vx), numel(vy));
    for i = 1:numel(vx)
        for j = 1:numel(vy)
            table_(i, j) = sum(x == vx(i) & y == vy(j));
        end
    end
    etiquettes = {vx, vy};
    if nargout > 1
        n = sum(table_(:));
        lignes = sum(table_, 2);
        colonnes = sum(table_, 1);
        attendu = lignes * colonnes / n;
        utile = attendu > 0;
        khi2 = sum((table_(utile) - attendu(utile)).^2 ./ attendu(utile));
        ddl = (numel(vx) - 1) * (numel(vy) - 1);
        if ddl > 0
            p = 1 - chi2cdf(khi2, ddl);
        else
            p = 1;
        end
    end
end
