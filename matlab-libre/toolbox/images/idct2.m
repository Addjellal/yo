function x = idct2(y, m, n)
%IDCT2 Transformée en cosinus discrète inverse bidimensionnelle.
    if nargin >= 2
        [hauteur, largeur] = size(y);
        if nargin < 3, n = largeur; end
        z = zeros(m, n);
        z(1:min(m, hauteur), 1:min(n, largeur)) = ...
            y(1:min(m, hauteur), 1:min(n, largeur));
        y = z;
    end
    y = double(y);
    intermediaire = zeros(size(y));
    for j = 1:size(y, 2)
        intermediaire(:, j) = idct(y(:, j));
    end
    x = zeros(size(y));
    for i = 1:size(y, 1)
        x(i, :) = idct(intermediaire(i, :).').';
    end
end
