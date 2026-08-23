function [muhat, sigmahat] = lognfit(x)
%LOGNFIT Estimation des paramètres d'une loi log-normale.
%   On ajuste une normale sur les logarithmes.
    x = double(x(:));
    if any(x <= 0)
        error('stats:lognfit:BadData', 'Les données doivent être strictement positives.');
    end
    l = log(x);
    muhat = mean(l);
    sigmahat = std(l);
end
