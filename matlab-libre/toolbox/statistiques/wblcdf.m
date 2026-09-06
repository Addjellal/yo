function p = wblcdf(x, a, b)
%WBLCDF Répartition de la loi de Weibull.
%   P = WBLCDF(X,A,B) rend 1 - exp(-(X/A)^B), où A est l'échelle et B la
%   forme.
%
%   Le paramètre de forme décide de tout : au-dessous de un le taux de
%   panne décroît — mortalité infantile —, à un il est constant — pannes
%   accidentelles, c'est l'exponentielle —, au-dessus il croît — usure.
%   C'est ce qui en fait la loi de la fiabilité.
%
%   La courbe en baignoire d'un équipement se décrit par trois Weibull
%   superposées, une par phase de vie.
%
%   Exemple :
%      wblcdf(1, 1, 1)                 % 1 - exp(-1) : l'exponentielle
%
%   Voir aussi WBLPDF, WBLINV, WBLRND, EXPCDF.
    if nargin < 2, a = 1; end
    if nargin < 3, b = 1; end
    p = zeros(size(x));
    positif = x >= 0;
    p(positif) = 1 - exp(-(x(positif) ./ a).^b);
end
