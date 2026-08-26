function lambdahat = poissfit(x)
%POISSFIT Estimation de l'intensité d'une loi de Poisson.
%   Le maximum de vraisemblance est la moyenne empirique.
    lambdahat = mean(double(x(:)));
end
