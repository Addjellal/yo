function [m, v] = expstat(mu)
%EXPSTAT Moyenne et variance de la loi exponentielle.
    mu = double(mu);
    m = mu;
    v = mu .^ 2;
    m(mu <= 0) = NaN;
    v(mu <= 0) = NaN;
end
