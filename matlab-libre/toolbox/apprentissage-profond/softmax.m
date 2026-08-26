function y = softmax(x)
%SOFTMAX Normalisation exponentielle, colonne par colonne.
    y = zeros(size(x));
    for j = 1:size(x, 2)
        v = x(:, j) - max(x(:, j));
        e = exp(v);
        y(:, j) = e / sum(e);
    end
end
