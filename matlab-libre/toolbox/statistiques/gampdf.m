function y = gampdf(x, a, b)
%GAMPDF Densité de la loi gamma, de forme A et d'échelle B.
%   Exemple :  gampdf(1, 1, 1)   % exp(-1), la loi exponentielle
    if nargin < 3, b = 1; end
    x = double(x);
    y = zeros(size(x));
    positif = x > 0;
    y(positif) = exp((a - 1) .* log(x(positif)) - x(positif) ./ b - ...
                     gammaln(a) - a .* log(b));
    % En zero la densite vaut 1/b pour une forme de 1, diverge en
    % dessous, s'annule au-dessus : le calcul general y ferait 0*log(0).
    if a == 1
        y(x == 0) = 1 ./ b;
    elseif a < 1
        y(x == 0) = Inf;
    end
end
