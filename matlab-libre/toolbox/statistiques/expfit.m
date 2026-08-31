function [muhat, muci] = expfit(x, alpha)
%EXPFIT Estimation du paramètre d'une loi exponentielle.
%   MU = EXPFIT(X) estime la moyenne de la loi exponentielle dont X
%   paraît tiré. Le maximum de vraisemblance est simplement la moyenne
%   empirique : c'est l'une des rares lois où l'estimation ne demande
%   aucune recherche numérique.
%
%   [MU,MUCI] = EXPFIT(X) rend aussi l'intervalle de confiance à 95 pour
%   cent. Il est exact, non approché : 2*N*MU/mu suit une loi du khi-deux
%   à 2N degrés de liberté, ce qui donne les bornes directement.
%
%   [...] = EXPFIT(X,ALPHA) donne un intervalle à 100*(1-ALPHA) pour cent.
%
%   Pour une matrice, chaque colonne est ajustée séparément.
%
%   Exemples :
%      x = exprnd(4, 500, 1);
%      [mu, ci] = expfit(x)              % mu proche de 4
%      expfit(x, 0.01)
%
%   Voir aussi EXPPDF, EXPCDF, EXPINV, EXPSTAT, MLE, FITDIST.
    if nargin < 2 || isempty(alpha)
        alpha = 0.05;
    end
    x = double(x);
    if ~isvector(x)
        colonnes = size(x, 2);
        muhat = zeros(1, colonnes);
        muci = zeros(2, colonnes);
        for j = 1:colonnes
            [muhat(j), muci(:, j)] = expfit(x(:, j), alpha);
        end
        return;
    end
    x = x(:);
    n = numel(x);
    muhat = mean(x);
    if n < 1
        muci = [0; Inf];
        return;
    end
    % 2*n*moyenne/mu suit un khi-deux a 2n degres : l'intervalle est exact.
    muci = [2 * n * muhat / chi2inv(1 - alpha / 2, 2 * n); ...
            2 * n * muhat / chi2inv(alpha / 2, 2 * n)];
end
