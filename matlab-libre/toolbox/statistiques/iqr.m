function r = iqr(x)
%IQR Écart interquartile.
    x = x(:);
    r = quantile(x, 0.75) - quantile(x, 0.25);
end
