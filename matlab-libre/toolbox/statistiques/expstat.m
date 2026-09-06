function [m, v] = expstat(mu)
%EXPSTAT Moyenne et variance de la loi exponentielle.
%   [M,V] = EXPSTAT(MU) rend MU et MU au carré.
%
%   L'égalité de la moyenne et de l'écart type est la signature de
%   l'exponentielle : un coefficient de variation de un. Sur des données
%   réelles, il dit immédiatement si le modèle sans mémoire tient.
%
%   Exemple :
%      [m, v] = expstat(3);            % 3 et 9
%      sqrt(v) / m                     % 1 : le coefficient de variation
%
%   Voir aussi EXPCDF, EXPPDF, POISSTAT.
    mu = double(mu);
    m = mu;
    v = mu .^ 2;
    m(mu <= 0) = NaN;
    v(mu <= 0) = NaN;
end
