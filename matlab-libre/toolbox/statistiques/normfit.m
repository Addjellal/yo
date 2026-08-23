function [muhat, sigmahat] = normfit(x)
%NORMFIT Estimation des paramètres d'une loi normale.
%   La moyenne est l'estimateur du maximum de vraisemblance ; l'écart
%   type est l'estimateur sans biais, en n-1, comme dans MATLAB.
    x = double(x(:));
    muhat = mean(x);
    sigmahat = std(x);
end
