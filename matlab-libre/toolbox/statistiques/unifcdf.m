function p = unifcdf(x, a, b)
%UNIFCDF Répartition de la loi uniforme continue sur [A,B].
%   P = UNIFCDF(X,A,B) croît linéairement de zéro en A à un en B.
%
%   C'est la loi de l'ignorance sur un intervalle borné : celle qui
%   maximise l'entropie quand on ne sait rien de plus que les bornes.
%
%   C'est aussi la brique de tout tirage aléatoire : toute autre loi
%   s'obtient d'un tirage uniforme par sa fonction quantile.
%
%   Exemple :
%      unifcdf(0.5, 0, 1)              % 0.5
%
%   Voir aussi UNIFPDF, UNIFINV, UNIDCDF, RAND.
    if nargin < 2, a = 0; end
    if nargin < 3, b = 1; end
    p = min(max((x - a) / (b - a), 0), 1);
end
