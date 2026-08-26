function [m, var] = chi2stat(v)
%CHI2STAT Moyenne et variance du khi-deux.
%   Exemple :  [m,v] = chi2stat(4)   % 4 et 8
    v = double(v);
    m = v;
    var = 2 * v;
    m(v <= 0) = NaN;
    var(v <= 0) = NaN;
end
