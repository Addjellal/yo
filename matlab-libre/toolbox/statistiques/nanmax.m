function [m, indice] = nanmax(x, y, dim)
%NANMAX Maximum en écartant les valeurs manquantes.
%   M = NANMAX(X) rend le plus grand élément de X sans tenir compte des
%   NaN. C'est déjà ce que fait MAX : NANMAX existe pour la symétrie de
%   la famille NAN..., et pour les programmes écrits avant que MAX ne
%   l'ait adopté.
%
%   [M,I] = NANMAX(X) rend aussi l'indice où le maximum a été trouvé.
%
%   M = NANMAX(X,Y) compare X et Y élément par élément ; là où l'un des
%   deux est NaN, c'est l'autre qui l'emporte.
%
%   M = NANMAX(X,[],DIM) cherche le long de la dimension DIM.
%
%   Exemples :
%      nanmax([1 NaN 5 2])               % 5
%      [m, i] = nanmax([1 NaN 5 2])      % m = 5, i = 3
%      nanmax([1 NaN], [NaN 4])          % [1 4]
%
%   Voir aussi MAX, NANMIN, NANMEAN, ISNAN.
    if nargin < 2
        [m, indice] = max(x);
    elseif nargin < 3
        [m, indice] = max(x, y);
    else
        [m, indice] = max(x, y, dim);
    end
end
