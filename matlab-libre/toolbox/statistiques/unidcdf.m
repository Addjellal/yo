function p = unidcdf(x, n)
%UNIDCDF Répartition de la loi uniforme discrète sur 1..N.
%   P = UNIDCDF(X,N) rend floor(X)/N, borné à un.
%
%   C'est la loi du dé : N issues équiprobables. Sa répartition est un
%   escalier, non une droite — la confondre avec la loi uniforme continue
%   décale tous les quantiles d'un demi.
%
%   Exemple :
%      unidcdf(3, 6)                   % 0.5 : la moitie des faces
%
%   Voir aussi UNIDINV, UNIDRND, UNIFCDF.
    [x, n] = statAjuster(x, n);
    p = floor(x) ./ n;
    p(x < 1) = 0;
    p(x >= n) = 1;
    p(n < 1 | n ~= round(n)) = NaN;
end
