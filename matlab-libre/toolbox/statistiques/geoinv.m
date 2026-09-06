function x = geoinv(y, p)
%GEOINV Quantile de la loi géométrique.
%   X = GEOINV(P,PROB) rend le nombre d'échecs avant le premier succès
%   au-dessous duquel on reste avec la probabilité P.
%
%   La loi géométrique est sans mémoire : après dix échecs, la loi du
%   nombre d'essais restants est la même qu'au départ. C'est la seule loi
%   discrète qui ait cette propriété, comme l'exponentielle est la seule
%   continue.
%
%   Exemple :
%      geoinv(0.5, 0.5)                % 0 : une chance sur deux au premier essai
%
%   Voir aussi GEOCDF, GEOPDF, GEORND.
    [y, p] = statAjuster(y, p);
    x = zeros(size(y));
    dedans = y > 0 & y < 1 & p > 0 & p < 1;
    x(dedans) = max(0, ceil(log(1 - y(dedans)) ./ log(1 - p(dedans)) - 1));
    x(y == 1) = Inf;
    x(p == 1) = 0;
    x(y < 0 | y > 1 | p <= 0 | p > 1) = NaN;
end
