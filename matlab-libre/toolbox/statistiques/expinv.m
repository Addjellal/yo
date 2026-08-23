function x = expinv(p, mu)
%EXPINV Quantile de la loi exponentielle de moyenne MU.
%   Exemple :  expinv(0.5, 1)   % log(2) = 0.6931
    if nargin < 2, mu = 1; end
    [p, mu] = statAjuster(p, mu);
    x = -mu .* log(1 - p);
    x(p == 0) = 0;    % evite le zero negatif de -0*log(1)
    x(p < 0 | p > 1 | mu <= 0) = NaN;
    x(p == 1 & mu > 0) = Inf;
end
