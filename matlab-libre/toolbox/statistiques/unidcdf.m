function p = unidcdf(x, n)
%UNIDCDF Répartition de la loi uniforme discrète sur 1..N.
    [x, n] = statAjuster(x, n);
    p = floor(x) ./ n;
    p(x < 1) = 0;
    p(x >= n) = 1;
    p(n < 1 | n ~= round(n)) = NaN;
end
