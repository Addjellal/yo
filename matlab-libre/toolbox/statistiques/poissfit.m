function [lambdahat, lambdaci] = poissfit(x, alpha)
%POISSFIT Estimation de l'intensité d'une loi de Poisson.
%   LAMBDA = POISSFIT(X) estime l'intensité de la loi de Poisson dont X
%   paraît tiré. Le maximum de vraisemblance est la moyenne empirique.
%
%   [LAMBDA,LAMBDACI] = POISSFIT(X) rend aussi l'intervalle de confiance
%   à 95 pour cent, obtenu par le lien exact entre la loi de Poisson et
%   celle du khi-deux : la somme des observations, multipliée par deux,
%   encadre l'intensité par deux quantiles de khi-deux.
%
%   [...] = POISSFIT(X,ALPHA) donne un intervalle à 100*(1-ALPHA) pour
%   cent.
%
%   Pour une matrice, chaque colonne est ajustée séparément.
%
%   Exemples :
%      x = poissrnd(3, 500, 1);
%      [lambda, ci] = poissfit(x)        % lambda proche de 3
%      poissfit(x, 0.01)
%
%   Voir aussi POISSPDF, POISSCDF, POISSINV, POISSTAT, MLE, FITDIST.
    if nargin < 2 || isempty(alpha)
        alpha = 0.05;
    end
    x = double(x);
    if ~isvector(x)
        colonnes = size(x, 2);
        lambdahat = zeros(1, colonnes);
        lambdaci = zeros(2, colonnes);
        for j = 1:colonnes
            [lambdahat(j), lambdaci(:, j)] = poissfit(x(:, j), alpha);
        end
        return;
    end
    x = x(:);
    n = numel(x);
    lambdahat = mean(x);
    total = sum(x);
    if n < 1
        lambdaci = [0; Inf];
        return;
    end
    % Le lien exact Poisson - khi-deux : P(N <= k | lambda) se lit dans
    % une repartition de khi-deux a 2(k+1) degres.
    if total == 0
        bas = 0;
    else
        bas = chi2inv(alpha / 2, 2 * total) / 2;
    end
    haut = chi2inv(1 - alpha / 2, 2 * (total + 1)) / 2;
    lambdaci = [bas / n; haut / n];
end
