function [coefficients, modele] = fitSurface(x, y, z, degre)
%FITSURFACE Ajustement polynomial d'une surface z = f(x,y).
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
