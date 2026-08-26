function y = nbinpdf(x, r, p)
%NBINPDF Probabilité de la loi binomiale négative.
%   X compte les échecs avant le R-ième succès, R pouvant être réel.
%
%   Exemple :  nbinpdf(2, 3, 0.5)   % 0.1875
    [x, r, p] = statAjuster(x, r, p);
    y = zeros(size(x));
    dedans = x >= 0 & x == round(x) & r > 0 & p > 0 & p <= 1;
    if any(dedans(:))
        xx = x(dedans); rr = r(dedans); pp = p(dedans);
        y(dedans) = exp(gammaln(rr + xx) - gammaln(rr) - gammaln(xx + 1) + ...
                        rr .* log(pp) + xx .* log(1 - pp));
    end
    y(r <= 0 | p <= 0 | p > 1) = NaN;
end
