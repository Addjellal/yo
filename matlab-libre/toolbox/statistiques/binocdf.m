function p = binocdf(x, n, pr)
%BINOCDF Répartition de la loi binomiale.
%   La somme des probabilités jusqu'à X s'écrit avec la bêta incomplète
%   régularisée : P(X <= k) = I_{1-p}(n-k, k+1). C'est exact pour tout N,
%   là où la somme directe coûterait N termes.
%
%   Exemple :  binocdf(5, 10, 0.5)   % 0.623046875
    [x, n, pr] = statAjuster(x, n, pr);
    p = zeros(size(x));
    k = floor(x);
    p(k >= n) = 1;
    dedans = k >= 0 & k < n;
    if any(dedans(:))
        p(dedans) = betainc(1 - pr(dedans), n(dedans) - k(dedans), k(dedans) + 1);
    end
    p(k < 0) = 0;
    p(pr < 0 | pr > 1 | n < 0 | n ~= round(n)) = NaN;
end
