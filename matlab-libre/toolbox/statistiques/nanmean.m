function m = nanmean(x, dim)
%NANMEAN Moyenne en écartant les valeurs manquantes.
%   M = NANMEAN(X) rend la moyenne de X en ignorant les NaN. Pour un
%   vecteur, c'est un scalaire ; pour une matrice, une ligne de moyennes,
%   une par colonne. Une colonne entièrement NaN donne NaN, faute de
%   quoi que ce soit à moyenner.
%
%   M = NANMEAN(X,DIM) moyenne le long de la dimension DIM.
%
%   NANMEAN(X) est un raccourci pour MEAN(X,'omitnan'), qui est la forme
%   recommandée depuis R2015a ; NANMEAN reste pour les programmes qui
%   l'emploient déjà.
%
%   Exemples :
%      nanmean([1 2 NaN 4])              % 2.3333
%      nanmean([1 NaN; 3 4])             % [2 4]
%      nanmean([1 NaN; 3 4], 2)          % [1 ; 3.5]
%      nanmean([NaN NaN])                % NaN
%
%   Voir aussi MEAN, NANMEDIAN, NANSTD, NANSUM, ISNAN, RMMISSING.
    if nargin < 2
        m = mean(x, 'omitnan');
    else
        m = mean(x, dim, 'omitnan');
    end
end
