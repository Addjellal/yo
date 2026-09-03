function [n, bordsX, bordsY] = histogram2(x, y, varargin)
%HISTOGRAM2 Histogramme à deux dimensions.
%   HISTOGRAM2(X,Y) compte les couples (X,Y) par case d'un quadrillage
%   et trace le résultat.
%
%   HISTOGRAM2(X,Y,NBINS) impose le nombre de classes, HISTOGRAM2(X,Y,
%   BORDSX,BORDSY) les bords.
%
%   [N,BORDSX,BORDSY] = HISTOGRAM2(...) rend les effectifs et les bords.
%
%   Le rendu de MatLibre est le quadrillage en couleurs — le
%   'DisplayStyle','tile' de MATLAB — plutôt que les barres en
%   perspective : sur une densité, les barres du fond se cachent entre
%   elles.
%
%   Exemple :
%      x = randn(1, 500);  y = x + 0.5 * randn(1, 500);
%      histogram2(x, y, [12 12]);
%
%   Voir aussi HISTCOUNTS2, HISTOGRAM, IMAGESC, HEATMAP.
    [n, bordsX, bordsY] = histcounts2(x, y, varargin{:});
    centresX = (bordsX(1:end-1) + bordsX(2:end)) / 2;
    centresY = (bordsY(1:end-1) + bordsY(2:end)) / 2;
    % imagesc range ses lignes suivant Y : le comptage se transpose.
    imagesc([centresX(1) centresX(end)], [centresY(1) centresY(end)], n');
    axis('xy');
    colorbar();
    xlabel('x');
    ylabel('y');
    if nargout == 0
        clear n bordsX bordsY;
    end
end
