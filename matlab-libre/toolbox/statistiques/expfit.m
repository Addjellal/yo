function muhat = expfit(x)
%EXPFIT Estimation du paramètre d'une loi exponentielle.
%   Le maximum de vraisemblance est la moyenne empirique.
    muhat = mean(double(x(:)));
end
