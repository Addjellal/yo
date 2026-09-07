function [m, v] = tstat(nu)
%TSTAT Moyenne et variance de la loi de Student.
%   La moyenne n'existe que pour NU > 1, la variance que pour NU > 2.
%
%   Exemple :
%      [m, v] = tstat(10);
%      m                           % 0 : elle est centree des que nu > 1
%      v                           % 1.25 = nu/(nu-2)
%
%   Voir aussi TCDF, TINV, TRND, PDF, CDF, ICDF.
    nu = double(nu);
    m = NaN(size(nu));
    v = NaN(size(nu));
    m(nu > 1) = 0;
    grand = nu > 2;
    v(grand) = nu(grand) ./ (nu(grand) - 2);
end
