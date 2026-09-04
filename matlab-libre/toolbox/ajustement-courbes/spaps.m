function [pp, valeurs, rho] = spaps(x, y, tolerance, w)
%SPAPS Spline la plus lisse qui reste dans une tolérance.
%   PP = SPAPS(X,Y,TOL) rend la spline dont l'intégrale du carré de la
%   dérivée seconde est la plus petite parmi celles dont la somme
%   pondérée des carrés des écarts ne dépasse pas TOL.
%
%   C'est le problème inverse de CSAPS : au lieu de fixer le compromis
%   entre fidélité et douceur, on fixe la fidélité qu'on exige et l'on
%   prend la courbe la plus lisse qui la respecte. TOL se lit donc dans
%   l'unité des données au carré — c'est le bruit qu'on accepte de ne pas
%   suivre.
%
%   PP = SPAPS(X,Y,TOL,W) pondère les points.
%   [PP,VALEURS,RHO] = SPAPS(...) rend aussi les valeurs lissées aux
%   points et le paramètre de lissage employé.
%
%   MatLibre rend la spline sous forme de morceaux polynomiaux, forme que
%   FNVAL, FNDER et PPVAL acceptent ; MATLAB la rend en B-forme.
%
%   Exemple :
%      rng(1);
%      x = linspace(0, 2*pi, 60)';
%      y = sin(x) + 0.05 * randn(size(x));
%      pp = spaps(x, y, 60 * 0.05^2);
%      max(abs(ppval(pp, x) - sin(x))) < 0.1
%
%   Voir aussi CSAPS, SPAP2, SPLINE, FNVAL.
    x = double(x(:));
    y = double(y(:));
    n = numel(x);
    if nargin < 4 || isempty(w)
        w = ones(n, 1);
    else
        w = double(w(:));
    end
    if nargin < 3 || isempty(tolerance)
        tolerance = 0;
    end
    if tolerance <= 0
        pp = csaps(x, y, 1, [], w);
        valeurs = ppval(pp, x);
        rho = 1;
        return
    end
    % Le paramètre de lissage est cherché par dichotomie sur son
    % logarithme : l'écart croît avec le lissage, la recherche est donc
    % monotone et sûre.
    basse = -12;
    haute = 12;
    for tour = 1:60
        milieu = (basse + haute) / 2;
        lambda = 10 ^ milieu;
        p = 1 / (1 + lambda);
        courant = csaps(x, y, p, [], w);
        ecart = sum(w .* (y - ppval(courant, x)) .^ 2);
        if ecart > tolerance
            haute = milieu;
        else
            basse = milieu;
        end
        if abs(ecart - tolerance) < 1e-12 * max(1, tolerance)
            break
        end
    end
    lambda = 10 ^ ((basse + haute) / 2);
    rho = 1 / (1 + lambda);
    pp = csaps(x, y, rho, [], w);
    valeurs = ppval(pp, x);
end
