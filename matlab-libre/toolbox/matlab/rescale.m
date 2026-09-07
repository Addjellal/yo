function y = rescale(x, bas, haut)
%RESCALE Remise à l'échelle linéaire d'un tableau.
%   Y = RESCALE(X) ramène les valeurs dans [0,1].
%   Y = RESCALE(X,A,B) les ramène dans [A,B].
%
%   Exemple :
%      rescale([2 4 6])            % 0 0.5 1
%      rescale([2 4 6], 10, 20)    % 10 15 20
%
%   Voir aussi NORMALIZE, MIN, MAX.
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
