function [muhat, sigmahat] = lognfit(x)
%LOGNFIT Estimation des paramètres d'une loi log-normale.
%   On ajuste une normale sur les logarithmes.
%
%   Exemple :
%      rng(1);
%      [mu, sigma] = lognfit(lognrnd(1, 0.5, 5000, 1));
%      abs(mu - 1) < 0.05 && abs(sigma - 0.5) < 0.05
    x = double(x(:));
    if any(x <= 0)
        error('stats:lognfit:BadData', 'Les données doivent être strictement positives.');
    end
    l = log(x);
    muhat = mean(l);
    sigmahat = std(l);
end
