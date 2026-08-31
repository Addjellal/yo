function s = nanstd(x, normalisation, dim)
%NANSTD Écart type en écartant les valeurs manquantes.
%   S = NANSTD(X) rend l'écart type de X en ignorant les NaN, normalisé
%   par N-1 où N est le nombre de valeurs présentes — non le nombre
%   d'éléments.
%
%   S = NANSTD(X,1) normalise par N. S = NANSTD(X,0) revient au défaut.
%
%   S = NANSTD(X,NORMALISATION,DIM) travaille le long de DIM.
%
%   NANSTD(X) est un raccourci pour STD(X,'omitnan').
%
%   Exemples :
%      nanstd([1 2 NaN 3])               % 1, comme std([1 2 3])
%      nanstd([1 2 NaN 3], 1)            % 0.8165
%      nanstd([1 NaN; 3 5])              % [1.4142 0]
%
%   Voir aussi STD, NANVAR, NANMEAN, VAR.
    if nargin < 2 || isempty(normalisation)
        normalisation = 0;
    end
    if nargin < 3
        s = std(x, normalisation, 'omitnan');
    else
        s = std(x, normalisation, dim, 'omitnan');
    end
end
