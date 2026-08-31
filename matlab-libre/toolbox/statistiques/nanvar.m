function v = nanvar(x, normalisation, dim)
%NANVAR Variance en écartant les valeurs manquantes.
%   V = NANVAR(X) rend la variance de X en ignorant les NaN, normalisée
%   par N-1 où N compte les seules valeurs présentes.
%
%   V = NANVAR(X,1) normalise par N ; V = NANVAR(X,0) revient au défaut.
%
%   V = NANVAR(X,NORMALISATION,DIM) travaille le long de DIM.
%
%   NANVAR(X) est un raccourci pour VAR(X,'omitnan').
%
%   Exemples :
%      nanvar([1 2 NaN 3])               % 1
%      nanvar([1 2 NaN 3], 1)            % 0.6667
%
%   Voir aussi VAR, NANSTD, NANMEAN, NANCOV.
    if nargin < 2 || isempty(normalisation)
        normalisation = 0;
    end
    if nargin < 3
        v = var(x, normalisation, 'omitnan');
    else
        v = var(x, normalisation, dim, 'omitnan');
    end
end
