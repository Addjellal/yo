function p = unifcdf(x, a, b)
%UNIFCDF Répartition de la loi uniforme continue sur [A,B].
    if nargin < 2, a = 0; end
    if nargin < 3, b = 1; end
    p = min(max((x - a) / (b - a), 0), 1);
end
