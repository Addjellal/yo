function [valeurs, etats] = matlibre_sl_hasard(etats, gaussien, un, deux)
%MATLIBRE_SL_HASARD Le tirage suivant des blocs de nombres au hasard.
%   [V,E] = MATLIBRE_SL_HASARD(E,GAUSSIEN,UN,DEUX) avance d'un tirage
%   l'état E de chaque élément et rend la valeur tirée. Pour un bruit
%   gaussien (GAUSSIEN vrai), UN est la moyenne et DEUX la variance ; pour
%   un bruit uniforme, UN est le minimum et DEUX le maximum.
%
%   Le générateur est celui de Park et Miller, x <- 16807 x modulo
%   2^31 - 1, et la gaussienne vient de deux tirages par la méthode de
%   Box et Muller. C'est un générateur que chacun peut refaire : la même
%   graine donne la même suite, d'une simulation à l'autre et d'une
%   machine à l'autre. Il ne reproduit pas les suites de Simulink, dont
%   l'algorithme n'est pas documenté.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [v, e] = matlibre_sl_hasard(1, false, 0, 1);
%      v                                   % 16807 / (2^31 - 1)
%
%   Voir aussi SIM, MATLIBRE_SL_EXECUTER.
    m = 2147483647;
    valeurs = zeros(numel(etats), 1);
    for i = 1:numel(etats)
        e = mod(16807 * etats(i), m);
        u1 = e / m;
        if gaussien
            e = mod(16807 * e, m);
            u2 = e / m;
            valeurs(i) = un(i) + sqrt(deux(i)) * sqrt(-2 * log(u1)) * cos(2 * pi * u2);
        else
            valeurs(i) = un(i) + (deux(i) - un(i)) * u1;
        end
        etats(i) = e;
    end
end
