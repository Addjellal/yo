function [compte, positions] = imhist(x, n)
%IMHIST Histogramme d'une image.
    if nargin < 2
        n = 256;
    end
    x = im2double(x);
    positions = ((0:n-1) / (n - 1)).';
    compte = zeros(n, 1);
    v = x(:);
    for k = 1:numel(v)
        indice = min(n, max(1, round(v(k) * (n - 1)) + 1));
        compte(indice) = compte(indice) + 1;
    end
    if nargout == 0
        bar(positions, compte);
        title('Histogramme');
    end
end
