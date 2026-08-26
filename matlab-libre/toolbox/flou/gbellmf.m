function y = gbellmf(x, p)
%GBELLMF Cloche généralisée de paramètres [a b c].
    y = 1 ./ (1 + abs((x - p(3)) / p(1)) .^ (2 * p(2)));
end
