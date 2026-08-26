function [m, v] = raylstat(b)
%RAYLSTAT Moyenne et variance de la loi de Rayleigh.
%   Exemple :  [m,v] = raylstat(1)   % sqrt(pi/2) et 2 - pi/2
    b = double(b);
    m = b * sqrt(pi / 2);
    v = (2 - pi / 2) * b .^ 2;
    m(b <= 0) = NaN;
    v(b <= 0) = NaN;
end
