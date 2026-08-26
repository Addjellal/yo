function y = rescale(x, bas, haut)
%RESCALE Remise à l'échelle linéaire d'un tableau.
%   Y = RESCALE(X) ramène les valeurs dans [0,1].
%   Y = RESCALE(X,A,B) les ramène dans [A,B].
    if nargin < 2
        bas = 0;
    end
    if nargin < 3
        haut = 1;
    end
    mn = min(x(:));
    mx = max(x(:));
    if mx == mn
        y = repmat(bas, size(x));
    else
        y = bas + (x - mn) * (haut - bas) / (mx - mn);
    end
end
