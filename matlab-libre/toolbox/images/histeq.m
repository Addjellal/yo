function y = histeq(x, n)
%HISTEQ Égalisation d'histogramme.
    if nargin < 2
        n = 256;
    end
    x = im2double(x);
    [compte, ~] = imhist(x, n);
    cumul = cumsum(compte) / sum(compte);
    y = zeros(size(x));
    for k = 1:numel(x)
        indice = min(n, max(1, round(x(k) * (n - 1)) + 1));
        y(k) = cumul(indice);
    end
end
