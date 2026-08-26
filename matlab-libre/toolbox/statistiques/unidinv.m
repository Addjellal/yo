function x = unidinv(p, n)
%UNIDINV Quantile de la loi uniforme discrète sur 1..N.
    [p, n] = statAjuster(p, n);
    x = ceil(p .* n);
    x(p <= 0) = NaN;
    x(p > 1 | p < 0) = NaN;
    x(n < 1 | n ~= round(n)) = NaN;
end
