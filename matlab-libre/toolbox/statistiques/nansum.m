function s = nansum(x, dim)
%NANSUM Somme en écartant les valeurs manquantes.
%   S = NANSUM(X) additionne X en traitant chaque NaN comme un zéro.
%   Une colonne entièrement NaN donne donc 0 — c'est la convention de
%   MATLAB, et elle diffère de NANMEAN, qui rend NaN dans ce cas.
%
%   S = NANSUM(X,DIM) additionne le long de la dimension DIM.
%
%   NANSUM(X) est un raccourci pour SUM(X,'omitnan').
%
%   Exemples :
%      nansum([1 2 NaN 4])               % 7
%      nansum([NaN NaN])                 % 0
%      nansum([1 NaN; 3 4], 2)           % [1 ; 7]
%
%   Voir aussi SUM, NANMEAN, NANMAX, NANMIN.
    if nargin < 2
        s = sum(x, 'omitnan');
    else
        s = sum(x, dim, 'omitnan');
    end
end
