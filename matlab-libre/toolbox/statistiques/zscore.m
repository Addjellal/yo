function [z, mu, sigma] = zscore(x)
%ZSCORE Centrage et réduction colonne par colonne.
    if isvector(x)
        mu = mean(x);
        sigma = std(x);
        if sigma == 0
            sigma = 1;
        end
        z = (x - mu) ./ sigma;
        return;
    end
    mu = mean(x);
    sigma = std(x);
    z = zeros(size(x));
    for j = 1:size(x, 2)
        s = sigma(j);
        if s == 0
            s = 1;
        end
        z(:, j) = (x(:, j) - mu(j)) / s;
    end
end
