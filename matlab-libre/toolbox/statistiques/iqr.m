function r = iqr(x)
%IQR Écart interquartile.
%   R = IQR(X) rend la différence entre le troisième et le premier
%   quartile : l'étendue de la moitié centrale des données.
%
%   C'est une mesure de dispersion robuste : déplacer un quart des données
%   à l'infini ne la change pas, là où l'écart type deviendrait infini.
%   C'est pourquoi elle sert à définir les valeurs aberrantes — au-delà
%   d'un quartile plus ou moins une fois et demie l'écart interquartile.
%
%   Pour une loi normale, elle vaut 1,349 fois l'écart type : c'est le
%   facteur qui permet de comparer les deux.
%
%   Exemple :
%      iqr([1 2 3 4 100])              % insensible a l'aberrant
%      abs(iqr(randn(100000,1)) - 1.349) < 0.02
%
%   Voir aussi MAD, STD, PRCTILE, ISOUTLIER.
    x = x(:);
    r = quantile(x, 0.75) - quantile(x, 0.25);
end
