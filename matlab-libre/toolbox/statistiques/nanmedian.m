function m = nanmedian(x, dim)
%NANMEDIAN Médiane en écartant les valeurs manquantes.
%   M = NANMEDIAN(X) rend la médiane de X en ignorant les NaN : la
%   médiane porte sur les seules valeurs présentes, non sur un vecteur
%   qu'un NaN suffirait à rendre indéfini.
%
%   M = NANMEDIAN(X,DIM) travaille le long de la dimension DIM.
%
%   NANMEDIAN(X) est un raccourci pour MEDIAN(X,'omitnan').
%
%   Exemples :
%      nanmedian([1 NaN 3 100])          % 3
%      nanmedian([1 NaN; 3 4])           % [2 4]
%      nanmedian([NaN NaN])              % NaN
%
%   Voir aussi MEDIAN, NANMEAN, NANSTD, PRCTILE, QUANTILE.
    if nargin < 2
        m = median(x, 'omitnan');
    else
        m = median(x, dim, 'omitnan');
    end
end
