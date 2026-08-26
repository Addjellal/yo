function k = kurtosis(x)
%KURTOSIS Coefficient d'aplatissement (3 pour une loi normale).
    x = x(:);
    n = numel(x);
    m = mean(x);
    ecart = std(x, 1);
    if ecart == 0
        k = NaN;
    else
        k = sum((x - m) .^ 4) / (n * ecart ^ 4);
    end
end
