function [bas, haut] = bounds(x, dim)
%BOUNDS Minimum et maximum en un seul appel.
%   [B,H] = BOUNDS(X) rend le plus petit et le plus grand élément.
%
%   Exemple :
%      [bas, haut] = bounds([3 1 4 1 5]);
%      [bas haut]                  % 1 5
%
%   Voir aussi MIN, MAX, RANGE.
    if nargin < 2
        bas = min(x(:));
        haut = max(x(:));
    else
        bas = min(x, [], dim);
        haut = max(x, [], dim);
    end
end
