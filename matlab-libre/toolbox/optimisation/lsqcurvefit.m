function [p, residu] = lsqcurvefit(modele, p0, xdata, ydata, bas, haut)
%LSQCURVEFIT Ajustement non linéaire au sens des moindres carrés.
%   P = LSQCURVEFIT(MODELE,P0,X,Y) minimise la somme des carrés des écarts
%   entre MODELE(P,X) et Y.
    if nargin < 5, bas = []; end
    if nargin < 6, haut = []; end
    xdata = xdata(:);
    ydata = ydata(:);
    objectif = @(p) sum((reshape(modele(p, xdata), numel(ydata), 1) - ydata) .^ 2) ...
                    + bornes(p, bas, haut);
    p = fminsearch(objectif, p0);
    residu = reshape(modele(p, xdata), numel(ydata), 1) - ydata;
end

function v = bornes(p, bas, haut)
    v = 0;
    p = p(:);
    if ~isempty(bas)
        v = v + 1e6 * sum(max(bas(:) - p, 0) .^ 2);
    end
    if ~isempty(haut)
        v = v + 1e6 * sum(max(p - haut(:), 0) .^ 2);
    end
end
