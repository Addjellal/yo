function [p, resnorm, residu, exitflag, sortie, multiplicateurs, jacobienne] = ...
        lsqcurvefit(modele, p0, xdata, ydata, bas, haut, options)
%LSQCURVEFIT Ajustement non linéaire au sens des moindres carrés.
%   P = LSQCURVEFIT(MODELE,P0,X,Y) minimise la somme des carrés des écarts
%   entre MODELE(P,X) et Y. P0 est le point de départ ; le modèle prend
%   les paramètres d'abord, l'abscisse ensuite — c'est ce qui distingue
%   LSQCURVEFIT de LSQNONLIN, où l'on écrit soi-même la différence.
%
%   P = LSQCURVEFIT(MODELE,P0,X,Y,LB,UB) borne les paramètres, et
%   LSQCURVEFIT(...,OPTIONS) règle la tolérance et le nombre d'itérations
%   ('TolFun', 'TolX', 'MaxIter').
%
%   [P,RESNORM,RESIDU,EXITFLAG,SORTIE,MULTIPLICATEURS,JACOBIENNE] =
%   LSQCURVEFIT(...) rend la somme des carrés au point trouvé, le vecteur
%   des écarts, le drapeau de sortie, le nombre d'itérations, les
%   multiplicateurs des bornes actives et la matrice jacobienne.
%
%   La minimisation est celle de LSQNONLIN : Levenberg-Marquardt, qui
%   passe continûment de la descente de gradient loin de la solution à la
%   méthode de Gauss-Newton près d'elle, et projette sur les bornes.
%
%   Exemple :
%      % Une exponentielle décroissante, retrouvée à partir de ses
%      % propres valeurs.
%      t = (0:0.5:3)';
%      y = 3 * exp(-0.5 * t);
%      p = lsqcurvefit(@(p, t) p(1) * exp(p(2) * t), [1; -1], t, y);
%      round(p, 3)                    % [3; -0.5]
%
%   Voir aussi LSQNONLIN, LSQLIN, FMINSEARCH, POLYFIT, FIT.
    if nargin < 5, bas = []; end
    if nargin < 6, haut = []; end
    if nargin < 7, options = struct(); end
    xdata = xdata(:);
    ydata = ydata(:);
    forme = size(p0);
    ecart = @(p) reshape(modele(reshape(p, forme), xdata), numel(ydata), 1) - ydata;
    [p, resnorm, residu, exitflag, sortie] = lsqnonlin(ecart, p0(:), bas, haut, options);
    p = reshape(p, forme);
    if nargout > 5
        multiplicateurs = matlibre_multiplicateurs_bornes(p(:), bas, haut);
    end
    if nargout > 6
        jacobienne = matlibre_jacobienne_residu(ecart, p(:), residu);
    end
end
