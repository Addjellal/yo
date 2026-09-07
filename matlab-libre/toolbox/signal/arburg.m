function [a, e, k] = arburg(x, p)
%ARBURG Modèle autorégressif par la méthode de Burg.
%   [A,E,K] = ARBURG(X,P) minimise, à chaque ordre, la somme des erreurs
%   de prédiction avant et arrière sous la contrainte de la récurrence de
%   Levinson. Contrairement à Yule-Walker, la méthode ne suppose aucune
%   fenêtre : elle donne des estimations plus nettes sur les séries
%   courtes, et le filtre reste toujours stable.
%
%   Exemple :
%      rng(1);
%      x = sin(2 * pi * 0.1 * (0:199)') + 0.1 * randn(200, 1);
%      [a, e] = arburg(x, 4);
%      all(abs(roots(a)) < 1) % 1 : Burg garantit un modele stable
%
%   Voir aussi ARYULE, ARCOV, ARMCOV, PBURG.
    x = double(x(:));
    n = numel(x);
    avant = x;
    arriere = x;
    a = 1;
    e = sum(abs(x) .^ 2) / n;
    k = zeros(p, 1);
    for m = 1:p
        haut = -2 * sum(conj(avant(m+1:n)) .* arriere(m:n-1));
        bas = sum(abs(avant(m+1:n)) .^ 2) + sum(abs(arriere(m:n-1)) .^ 2);
        if bas == 0
            k(m) = 0;
        else
            k(m) = haut / bas;
        end
        nouveauAvant = avant(m+1:n) + k(m) * arriere(m:n-1);
        nouveauArriere = arriere(m:n-1) + conj(k(m)) * avant(m+1:n);
        avant(m+1:n) = nouveauAvant;
        arriere(m+1:n) = nouveauArriere;
        a = [a 0] + k(m) * [0 conj(fliplr(a))];
        e = e * (1 - abs(k(m)) ^ 2);
    end
end
