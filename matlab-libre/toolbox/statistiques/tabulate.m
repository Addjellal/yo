function t = tabulate(x)
%TABULATE Effectifs et fréquences des valeurs distinctes.
%   T = TABULATE(X) rend une matrice [valeur, effectif, pourcentage].
    x = x(:);
    v = unique(x);
    t = zeros(numel(v), 3);
    for k = 1:numel(v)
        n = sum(x == v(k));
        t(k, 1) = v(k);
        t(k, 2) = n;
        t(k, 3) = 100 * n / numel(x);
    end
end
