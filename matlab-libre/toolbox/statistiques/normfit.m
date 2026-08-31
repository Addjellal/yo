function [muhat, sigmahat, muci, sigmaci] = normfit(x, alpha)
%NORMFIT Estimation des paramètres d'une loi normale.
%   [MU,SIGMA] = NORMFIT(X) estime la moyenne et l'écart type de la loi
%   normale dont X paraît tiré. MU est la moyenne empirique ; SIGMA est
%   l'estimateur sans biais, celui qui divise par N-1 — non celui du
%   maximum de vraisemblance, qui divise par N.
%
%   [MU,SIGMA,MUCI,SIGMACI] = NORMFIT(X) rend aussi les intervalles de
%   confiance à 95 pour cent des deux paramètres. Celui de la moyenne
%   vient de la loi de Student, celui de l'écart type de la loi du
%   khi-deux ; ce dernier n'est pas centré sur l'estimation, la loi du
%   khi-deux n'étant pas symétrique.
%
%   [...] = NORMFIT(X,ALPHA) donne des intervalles à 100*(1-ALPHA) pour
%   cent : ALPHA = 0.01 pour 99 pour cent.
%
%   Pour une matrice, chaque colonne est ajustée séparément.
%
%   Exemples :
%      x = normrnd(5, 2, 500, 1);
%      [mu, sigma] = normfit(x)              % proche de 5 et 2
%      [mu, sigma, muci, sigmaci] = normfit(x, 0.01)
%      normfit([randn(100,1), randn(100,1) + 10])   % deux colonnes
%
%   Voir aussi NORMPDF, NORMCDF, NORMINV, NORMLIKE, MLE, FITDIST.
    if nargin < 2 || isempty(alpha)
        alpha = 0.05;
    end
    x = double(x);
    if ~isvector(x)
        colonnes = size(x, 2);
        muhat = zeros(1, colonnes);
        sigmahat = zeros(1, colonnes);
        muci = zeros(2, colonnes);
        sigmaci = zeros(2, colonnes);
        for j = 1:colonnes
            [muhat(j), sigmahat(j), muci(:, j), sigmaci(:, j)] = ...
                normfit(x(:, j), alpha);
        end
        return;
    end
    x = x(:);
    n = numel(x);
    muhat = mean(x);
    sigmahat = std(x);
    if n < 2
        muci = [-Inf; Inf];
        sigmaci = [0; Inf];
        return;
    end
    ddl = n - 1;
    marge = tinv(1 - alpha / 2, ddl) * sigmahat / sqrt(n);
    muci = [muhat - marge; muhat + marge];
    sigmaci = [sigmahat * sqrt(ddl / chi2inv(1 - alpha / 2, ddl)); ...
               sigmahat * sqrt(ddl / chi2inv(alpha / 2, ddl))];
end
