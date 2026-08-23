function y = wcodemat(x, nbcodes, mode, absolu)
%WCODEMAT Met une matrice à l'échelle des indices de couleur.
%   Y = WCODEMAT(X,NBCODES) ramène X dans 1..NBCODES.
%
%   Exemple :  wcodemat([0 1], 4)   % [1 4]
    if nargin < 2 || isempty(nbcodes), nbcodes = 16; end
    if nargin < 3 || isempty(mode), mode = 'mat'; end
    if nargin < 4 || isempty(absolu), absolu = 1; end
    x = double(x);
    if absolu, x = abs(x); end
    switch lower(char(mode))
        case 'row'
            y = zeros(size(x));
            for i = 1:size(x, 1)
                y(i, :) = echelle(x(i, :), nbcodes);
            end
        case {'col', 'column'}
            y = zeros(size(x));
            for j = 1:size(x, 2)
                y(:, j) = echelle(x(:, j), nbcodes);
            end
        otherwise
            y = echelle(x, nbcodes);
    end
end

function y = echelle(x, nbcodes)
    bas = min(x(:));
    haut = max(x(:));
    if haut == bas
        y = ones(size(x));
    else
        y = 1 + floor((nbcodes - 1) * (x - bas) / (haut - bas) + 0.5);
    end
end
