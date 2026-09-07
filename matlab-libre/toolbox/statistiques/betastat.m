function [m, v] = betastat(a, b)
%BETASTAT Moyenne et variance de la loi bêta.
%   Exemple :
%      [m,v] = betastat(1, 1)   % 0.5 et 1/12
%
%   Voir aussi BETAPDF, BETACDF, BETAINV, BETARND, PDF, CDF.
    [a, b] = statAjuster(a, b);
    somme = a + b;
    m = a ./ somme;
    v = a .* b ./ (somme .^ 2 .* (somme + 1));
    mauvais = a <= 0 | b <= 0;
    m(mauvais) = NaN;
    v(mauvais) = NaN;
end
