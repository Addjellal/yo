function [m, v] = poisstat(lambda)
%POISSTAT Moyenne et variance de la loi de Poisson : toutes deux LAMBDA.
    lambda = double(lambda);
    m = lambda;
    v = lambda;
    m(lambda < 0) = NaN;
    v(lambda < 0) = NaN;
end
