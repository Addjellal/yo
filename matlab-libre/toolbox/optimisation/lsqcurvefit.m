function [p, residu] = lsqcurvefit(modele, p0, xdata, ydata, bas, haut)
%LSQCURVEFIT Ajustement non linéaire au sens des moindres carrés.
%   P = LSQCURVEFIT(MODELE,P0,X,Y) minimise la somme des carrés des écarts
%   entre MODELE(P,X) et Y. P0 est le point de départ ; le modèle prend
%   les paramètres d'abord, l'abscisse ensuite — c'est ce qui distingue
%   LSQCURVEFIT de LSQNONLIN, où l'on écrit soi-même la différence.
%
%   P = LSQCURVEFIT(MODELE,P0,X,Y,LB,UB) borne les paramètres.
%
%   Exemple :
%      % Une exponentielle décroissante, retrouvée à partir de ses
%      % propres valeurs.
%      t = (0:0.5:3)';
%      y = 3 * exp(-0.5 * t);
%      p = lsqcurvefit(@(p, t) p(1) * exp(p(2) * t), [1; -1], t, y);
%      round(p, 3)                    % [3; -0.5]
%
%   Voir aussi LSQNONLIN, LSQLIN, FMINSEARCH, POLYFIT.
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
