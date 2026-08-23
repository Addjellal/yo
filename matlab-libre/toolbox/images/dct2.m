function y = dct2(x, m, n)
%DCT2 Transformée en cosinus discrète bidimensionnelle.
%   Y = DCT2(X) applique DCT aux colonnes puis aux lignes.
    if nargin >= 2
        x = redimensionner(x, m, n, nargin);
    end
    % DCT sur chaque colonne, puis sur chaque ligne : la transformée
    % bidimensionnelle est séparable.
    x = double(x);
    intermediaire = zeros(size(x));
    for j = 1:size(x, 2)
        intermediaire(:, j) = dct(x(:, j));
    end
    y = zeros(size(x));
    for i = 1:size(x, 1)
        y(i, :) = dct(intermediaire(i, :).').';
    end
end

function x = redimensionner(x, m, n, nombreArguments)
    if nombreArguments < 3, n = size(x, 2); end
    y = zeros(m, n);
    lignes = 1:min(m, size(x, 1));
    colonnes = 1:min(n, size(x, 2));
    y(lignes, colonnes) = x(lignes, colonnes);
    x = y;
end
