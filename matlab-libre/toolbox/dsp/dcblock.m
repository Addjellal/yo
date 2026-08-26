function y = dcblock(x, alpha)
%DCBLOCK Filtre coupe-continu du premier ordre.
%   Y = DCBLOCK(X,ALPHA) applique y[n] = x[n] - x[n-1] + alpha*y[n-1].
    if nargin < 2
        alpha = 0.995;
    end
    y = filter([1 -1], [1 -alpha], x);
end
