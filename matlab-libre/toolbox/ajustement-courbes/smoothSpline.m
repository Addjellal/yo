function ylisse = smoothSpline(x, y, lambda)
%SMOOTHSPLINE Lissage par pénalisation de la dérivée seconde.
%   YLISSE = SMOOTHSPLINE(X,Y,LAMBDA) minimise
%      sum (y - f)^2 + lambda * sum (f'')^2
    if nargin < 3
        lambda = 1;
    end
    y = y(:);
    n = numel(y);
    D = zeros(n - 2, n);
    for k = 1:n-2
        D(k, k) = 1;
        D(k, k+1) = -2;
        D(k, k+2) = 1;
    end
    A = eye(n) + lambda * (D.' * D);
    ylisse = A \ y;
end
