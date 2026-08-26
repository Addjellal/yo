function y = unidpdf(x, n)
%UNIDPDF Probabilité de la loi uniforme discrète sur 1..N.
%   Exemple :  unidpdf(3, 6)   % 1/6, un dé
    [x, n] = statAjuster(x, n);
    y = zeros(size(x));
    dedans = x >= 1 & x <= n & x == round(x) & n >= 1 & n == round(n);
    y(dedans) = 1 ./ n(dedans);
    y(n < 1 | n ~= round(n)) = NaN;
end
