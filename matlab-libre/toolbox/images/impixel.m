function [r, v, b] = impixel(I, x, y)
%IMPIXEL Valeurs de pixels choisis.
%   P = IMPIXEL(I,X,Y) rend, une ligne par point, les composantes des
%   pixels aux colonnes X et aux lignes Y. Une image en niveaux de gris
%   donne trois composantes égales, comme dans MATLAB.
%
%   [R,V,B] = IMPIXEL(...) rend les trois composantes séparément.
%
%   MATLAB permet aussi de cliquer les points dans la figure ; MatLibre
%   n'a pas de figure cliquable, et demande donc les coordonnées.
%
%   Exemple :
%      I = mat2gray(magic(8));
%      p = impixel(I, [1 8], [1 8]);
%
%   Voir aussi IMSHOW, IMCROP, IMPROFILE, GINPUT.
    if nargin < 3
        error('images:impixel:Arguments', ...
              'MatLibre demande les coordonnées : impixel(I, X, Y).');
    end
    x = round(double(x(:)));
    y = round(double(y(:)));
    I = im2double(I);
    [m, n, canaux] = size(I);
    p = zeros(numel(x), 3);
    for k = 1:numel(x)
        if x(k) < 1 || x(k) > n || y(k) < 1 || y(k) > m
            p(k, :) = NaN;
            continue;
        end
        if canaux == 1
            p(k, :) = repmat(I(y(k), x(k)), 1, 3);
        else
            p(k, :) = reshape(I(y(k), x(k), 1:min(3, canaux)), 1, []);
        end
    end
    if nargout <= 1
        r = p;
    else
        r = p(:, 1);
        v = p(:, 2);
        b = p(:, 3);
    end
end
