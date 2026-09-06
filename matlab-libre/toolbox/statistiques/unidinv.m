function x = unidinv(p, n)
%UNIDINV Quantile de la loi uniforme discrète sur 1..N.
%   X = UNIDINV(P,N) rend le plus petit entier k tel que k/N >= P.
%
%   Le quantile d'une loi discrète est un entier : la fonction ne rend
%   jamais une valeur intermédiaire, et son inverse ne redonne donc pas
%   exactement P.
%
%   Exemple :
%      unidinv(0.5, 6)                 % 3
%
%   Voir aussi UNIDCDF, UNIDRND.
    [p, n] = statAjuster(p, n);
    x = ceil(p .* n);
    x(p <= 0) = NaN;
    x(p > 1 | p < 0) = NaN;
    x(n < 1 | n ~= round(n)) = NaN;
end
