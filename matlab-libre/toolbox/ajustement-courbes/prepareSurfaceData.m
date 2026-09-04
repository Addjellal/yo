function [xs, ys, zs, ws] = prepareSurfaceData(x, y, z, w)
%PREPARESURFACEDATA Met des données de surface en état d'être ajustées.
%   [X,Y,Z] = PREPARESURFACEDATA(X,Y,Z) rend trois vecteurs colonnes.
%   Quand Z est une matrice et que X et Y sont les vecteurs des colonnes
%   et des lignes, la grille est dépliée : à chaque valeur de Z
%   correspondent son abscisse et son ordonnée.
%
%   Les points non finis sont écartés.
%
%   Exemple :
%      [x, y, z] = prepareSurfaceData(1:3, 1:2, magic(3)(1:2, :));
%      numel(z)      % 6
%
%   Voir aussi PREPARECURVEDATA, FIT, SFIT.
    z = double(z);
    x = double(x);
    y = double(y);
    if ~isvector(z) && isvector(x) && isvector(y)
        [X, Y] = meshgrid(x(:).', y(:).');
        x = X;
        y = Y;
    end
    xs = x(:);
    ys = y(:);
    zs = z(:);
    if numel(xs) ~= numel(zs) || numel(ys) ~= numel(zs)
        error('curvefit:prepareSurfaceData:Tailles', ...
              'X, Y et Z doivent se correspondre.');
    end
    if nargin < 4 || isempty(w)
        ws = ones(numel(zs), 1);
    else
        ws = double(w(:));
    end
    garde = isfinite(xs) & isfinite(ys) & isfinite(zs) & isfinite(ws);
    xs = xs(garde);
    ys = ys(garde);
    zs = zs(garde);
    ws = ws(garde);
end
