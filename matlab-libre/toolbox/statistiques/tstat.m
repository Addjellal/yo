function [m, v] = tstat(nu)
%TSTAT Moyenne et variance de la loi de Student.
%   La moyenne n'existe que pour NU > 1, la variance que pour NU > 2.
    nu = double(nu);
    m = NaN(size(nu));
    v = NaN(size(nu));
    m(nu > 1) = 0;
    grand = nu > 2;
    v(grand) = nu(grand) ./ (nu(grand) - 2);
end
