function [m, v] = poisstat(lambda)
%POISSTAT Moyenne et variance de la loi de Poisson : toutes deux LAMBDA.
%   [M,V] = POISSTAT(LAMBDA) rend LAMBDA et LAMBDA.
%
%   Cette égalité est la contrainte forte de la loi de Poisson, et sa
%   principale limite : des comptages réels sont presque toujours plus
%   dispersés que cela. Le rapport variance sur moyenne — l'indice de
%   dispersion — mesure l'écart, et au-delà de un il faut une binomiale
%   négative.
%
%   Exemple :
%      [m, v] = poisstat(4);           % 4 et 4
%
%   Voir aussi POISSCDF, POISSRND, NBININV, EXPSTAT.
    lambda = double(lambda);
    m = lambda;
    v = lambda;
    m(lambda < 0) = NaN;
    v(lambda < 0) = NaN;
end
