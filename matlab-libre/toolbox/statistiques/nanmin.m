function [m, indice] = nanmin(x, y, dim)
%NANMIN Minimum en écartant les valeurs manquantes.
%   M = NANMIN(X) rend le plus petit élément de X sans tenir compte des
%   NaN, comme le fait déjà MIN.
%
%   [M,I] = NANMIN(X) rend aussi l'indice où le minimum a été trouvé.
%
%   M = NANMIN(X,Y) compare X et Y élément par élément ; là où l'un des
%   deux est NaN, c'est l'autre qui l'emporte.
%
%   M = NANMIN(X,[],DIM) cherche le long de la dimension DIM.
%
%   Exemples :
%      nanmin([3 NaN 1 2])               % 1
%      [m, i] = nanmin([3 NaN 1 2])      % m = 1, i = 3
%      nanmin([1 NaN], [NaN 4])          % [1 4]
%
%   Voir aussi MIN, NANMAX, NANMEAN, ISNAN.
    if nargin < 2
        [m, indice] = min(x);
    elseif nargin < 3
        [m, indice] = min(x, y);
    else
        [m, indice] = min(x, y, dim);
    end
end
