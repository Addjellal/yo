function p = gamcdf(x, a, b)
%GAMCDF Répartition de la loi gamma : la gamma incomplète régularisée.
    if nargin < 3, b = 1; end
    x = double(x);
    p = zeros(size(x));
    positif = x > 0;
    p(positif) = gammainc(x(positif) ./ b, a);
end
