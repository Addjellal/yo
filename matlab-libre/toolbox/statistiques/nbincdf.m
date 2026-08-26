function c = nbincdf(x, r, p)
%NBINCDF Répartition de la loi binomiale négative.
%   P(X <= k) = I_p(r, k+1), la bêta incomplète régularisée.
    [x, r, p] = statAjuster(x, r, p);
    k = floor(x);
    c = zeros(size(x));
    dedans = k >= 0 & r > 0 & p > 0 & p < 1;
    if any(dedans(:))
        c(dedans) = betainc(p(dedans), r(dedans), k(dedans) + 1);
    end
    c(k >= 0 & p == 1) = 1;
    c(k < 0) = 0;
    c(r <= 0 | p <= 0 | p > 1) = NaN;
end
