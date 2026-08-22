function [a, e] = lpc(x, p)
%LPC Coefficients de prédiction linéaire.
%   [A,E] = LPC(X,P) minimise l'erreur de prédiction d'ordre P.
    x = x(:).';
    n = numel(x);
    r = zeros(1, p + 1);
    for k = 0:p
        r(k + 1) = sum(x(1:n-k) .* x(1+k:n));
    end
    [a, e] = levinson(r, p);
end
