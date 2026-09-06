function p = gamcdf(x, a, b)
%GAMCDF Répartition de la loi gamma : la gamma incomplète régularisée.
%   P = GAMCDF(X,A,B) rend la probabilité qu'une variable gamma de forme A
%   et d'échelle B soit inférieure à X.
%
%   La gamma est la somme de A exponentielles indépendantes quand A est
%   entier : c'est le temps d'attente de la A-ième panne d'un processus
%   sans mémoire. Elle englobe l'exponentielle (A = 1) et le khi-deux
%   (A = V/2, B = 2).
%
%   Le paramètre de forme décide de l'allure : au-dessous de un la densité
%   diverge en zéro, au-dessus elle a un mode.
%
%   Exemple :
%      gamcdf(1, 1, 1)                 % 1 - exp(-1) : l'exponentielle
%
%   Voir aussi GAMPDF, GAMINV, CHI2CDF, EXPCDF.
    if nargin < 3, b = 1; end
    x = double(x);
    p = zeros(size(x));
    positif = x > 0;
    p(positif) = gammainc(x(positif) ./ b, a);
end
