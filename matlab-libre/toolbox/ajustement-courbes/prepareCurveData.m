function [xs, ys, ws] = prepareCurveData(x, y, w)
%PREPARECURVEDATA Met des données en état d'être ajustées.
%   [X,Y] = PREPARECURVEDATA(X,Y) rend deux vecteurs colonnes de nombres
%   en double précision, débarrassés des points non finis. Les données
%   arrivent souvent en lignes, en matrices ou avec des trous ; FIT les
%   veut en colonnes et sans trou.
%
%   [X,Y] = PREPARECURVEDATA([],Y) numérote les abscisses de un à N.
%   [X,Y,W] = PREPARECURVEDATA(X,Y,W) prépare aussi les poids.
%
%   Exemple :
%      [x, y] = prepareCurveData([], [1 NaN 3]);
%      x'      % 1 3
%
%   Voir aussi PREPARESURFACEDATA, FIT, EXCLUDEDATA.
    y = double(y(:));
    if isempty(x)
        x = (1:numel(y)).';
    else
        x = double(x(:));
    end
    if numel(x) ~= numel(y)
        error('curvefit:prepareCurveData:Tailles', ...
              'X et Y doivent avoir le même nombre d''éléments.');
    end
    if nargin < 3 || isempty(w)
        w = ones(numel(y), 1);
    else
        w = double(w(:));
    end
    garde = isfinite(x) & isfinite(y) & isfinite(w);
    xs = x(garde);
    ys = y(garde);
    ws = w(garde);
end
