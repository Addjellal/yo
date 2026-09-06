function [coefficients, modele] = fitSurface(x, y, z, degre)
%FITSURFACE Ajustement polynomial d'une surface z = f(x,y).
%   [COEFFICIENTS,MODELE] = FITSURFACE(X,Y,Z,DEGRE) ajuste un polynôme à
%   deux variables du degré total demandé, au sens des moindres carrés.
%   DEGRE vaut un par défaut, soit un plan.
%
%   Le nombre de coefficients croît vite : (D+1)(D+2)/2, soit trois pour
%   un plan, six au degré deux, dix au degré trois. Il faut au moins
%   autant de points que de coefficients, et de préférence bien plus,
%   sans quoi l'ajustement interpole le bruit.
%
%   Les points doivent aussi être répartis : tous alignés, ils ne
%   déterminent pas une surface, et le système devient singulier.
%
%   Exemple :
%      [x, y] = meshgrid(linspace(0, 1, 10));
%      z = 2 * x + 3 * y + 1;
%      c = fitSurface(x(:), y(:), z(:), 1);        % [1 2 3] a l'ordre pres
%
%   Voir aussi FIT, SFIT, GOODNESSOFFIT, POLYFIT.
    if nargin < 4
        degre = 1;
    end
    x = x(:); y = y(:); z = z(:);
    colonnes = {};
    for i = 0:degre
        for j = 0:degre-i
            colonnes{end+1} = (x .^ i) .* (y .^ j);
        end
    end
    A = zeros(numel(x), numel(colonnes));
    for k = 1:numel(colonnes)
        A(:, k) = colonnes{k};
    end
    coefficients = A \ z;
    modele = @(c, xx, yy) evaluerSurface(c, xx, yy, degre);
end

function v = evaluerSurface(c, x, y, degre)
    v = zeros(size(x));
    k = 1;
    for i = 0:degre
        for j = 0:degre-i
            v = v + c(k) * (x .^ i) .* (y .^ j);
            k = k + 1;
        end
    end
end
