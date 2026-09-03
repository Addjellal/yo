function [n, bordsX, bordsY] = histcounts2(x, y, varargin)
%HISTCOUNTS2 Comptage sur un quadrillage à deux dimensions.
%   N = HISTCOUNTS2(X,Y) compte les couples (X,Y) tombant dans chaque
%   case d'un quadrillage automatique. N(i,j) compte la case de la
%   i-ième classe en X et de la j-ième en Y.
%
%   N = HISTCOUNTS2(X,Y,NBINS) impose le nombre de classes : un scalaire
%   pour les deux axes, ou [NX NY].
%   N = HISTCOUNTS2(X,Y,BORDSX,BORDSY) impose les bords.
%
%   [N,BORDSX,BORDSY] = HISTCOUNTS2(...) rend aussi les bords employés.
%
%   Exemple :
%      [n, bx, by] = histcounts2([1 2 3], [1 1 2], [0 2 4], [0 1.5 3]);
%
%   Voir aussi HISTCOUNTS, HISTOGRAM2, ACCUMARRAY.
    x = double(x(:));
    y = double(y(:));
    nx = 10;
    ny = 10;
    bordsX = [];
    bordsY = [];
    if numel(varargin) == 1
        n = double(varargin{1});
        if isscalar(n)
            nx = n;
            ny = n;
        else
            nx = n(1);
            ny = n(2);
        end
    elseif numel(varargin) >= 2
        bordsX = double(varargin{1}(:))';
        bordsY = double(varargin{2}(:))';
    end
    if isempty(bordsX)
        bordsX = bordsAuto(x, nx);
    end
    if isempty(bordsY)
        bordsY = bordsAuto(y, ny);
    end
    ix = discretize(x, bordsX);
    iy = discretize(y, bordsY);
    n = zeros(numel(bordsX) - 1, numel(bordsY) - 1);
    for k = 1:numel(ix)
        if ~isnan(ix(k)) && ~isnan(iy(k))
            n(ix(k), iy(k)) = n(ix(k), iy(k)) + 1;
        end
    end
end

function b = bordsAuto(v, n)
    bas = min(v);
    haut = max(v);
    if isempty(bas)
        bas = 0;
        haut = 1;
    elseif bas == haut
        bas = bas - 0.5;
        haut = haut + 0.5;
    end
    b = linspace(bas, haut, n + 1);
end
