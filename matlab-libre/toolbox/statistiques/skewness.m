function s = skewness(x)
%SKEWNESS Coefficient d'asymétrie (moment d'ordre trois normalisé).
    x = x(:);
    n = numel(x);
    m = mean(x);
    ecart = std(x, 1);
    if ecart == 0
        s = NaN;
    else
        s = sum((x - m) .^ 3) / (n * ecart ^ 3);
    end
end
