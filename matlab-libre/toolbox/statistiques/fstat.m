function [m, v] = fstat(v1, v2)
%FSTAT Moyenne et variance de la loi de Fisher-Snedecor.
%   La moyenne n'existe que pour V2 > 2, la variance que pour V2 > 4 ;
%   ailleurs MATLAB rend NaN.
%
%   Exemple :  [m,v] = fstat(4, 10)   % 1.25 et 1.354166...
    [v1, v2] = statAjuster(v1, v2);
    m = NaN(size(v1));
    v = NaN(size(v1));
    ok = v2 > 2 & v1 > 0;
    m(ok) = v2(ok) ./ (v2(ok) - 2);
    ok = v2 > 4 & v1 > 0;
    v(ok) = 2 * v2(ok) .^ 2 .* (v1(ok) + v2(ok) - 2) ./ ...
            (v1(ok) .* (v2(ok) - 2) .^ 2 .* (v2(ok) - 4));
end
