function modele = fitglm(X, y, varargin)
%FITGLM Modèle linéaire généralisé.
%   M = FITGLM(X,Y) ajuste un modèle linéaire ordinaire. L'intérêt de la
%   fonction est ailleurs : elle traite les réponses qui ne sont pas
%   gaussiennes.
%
%   M = FITGLM(X,Y,'Distribution','binomial') ajuste une régression
%   logistique — Y vaut 0 ou 1, et le modèle prédit une probabilité.
%   'poisson' ajuste un comptage, 'gamma' et 'inverse gaussian' des
%   durées ou des grandeurs positives.
%
%   FITGLM(...,'Link',L) change la fonction de lien : 'identity',
%   'log', 'logit', 'probit', 'loglog', 'reciprocal'. Chaque loi a son
%   lien canonique par défaut.
%   FITGLM(...,'Intercept',false) retire l'ordonnée à l'origine.
%   FITGLM(...,'Weights',W) pondère les observations, ce qui pour une
%   binomiale donne le nombre d'essais.
%
%   Le modèle rendu est une structure : Coefficients, SE, tStat, pValue,
%   Fitted, Residuals, Deviance, LogLikelihood, AIC, BIC, Link,
%   Distribution. MatLibre n'a pas d'objet GeneralizedLinearModel ; la
%   structure en porte les mêmes champs.
%
%   L'ajustement est par moindres carrés repondérés itérativement, la
%   méthode classique : à chaque tour, la réponse est linéarisée autour
%   de la prédiction courante et pondérée par la variance attendue.
%
%   Exemple :
%      rng(1);
%      X = randn(200, 1);
%      p = 1 ./ (1 + exp(-(0.5 + 2 * X)));
%      y = double(rand(200, 1) < p);
%      m = fitglm(X, y, 'Distribution', 'binomial');
%      m.Coefficients
%
%   Voir aussi FITLM, GLMFIT, MNRFIT, REGRESS, ROBUSTFIT.
    X = double(X);
    if isvector(X) && size(X, 1) == 1
        X = X(:);
    end
    y = double(y(:));
    n = numel(y);
    distribution = 'normal';
    lien = '';
    poids = ones(n, 1);
    avecConstante = true;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'distribution', distribution = lower(char(varargin{k+1}));
            case 'link',         lien = lower(char(varargin{k+1}));
            case 'weights',      poids = double(varargin{k+1}(:));
            case 'intercept',    avecConstante = logical(varargin{k+1});
            case {'varnames', 'responsevar', 'predictorvars', 'options'}
                % Acceptées et sans effet.
            otherwise
                error('stats:fitglm:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if isempty(lien)
        lien = lienCanonique(distribution);
    end
    if avecConstante
        A = [ones(n, 1), X];
    else
        A = X;
    end
    p = size(A, 2);
    % Départ : une prédiction prudente, jamais au bord du domaine.
    mu = departGlm(y, distribution, poids);
    eta = appliquerLien(mu, lien);
    beta = zeros(p, 1);
    for iteration = 1:100
        derivee = deriveeLien(mu, lien);
        variance = fonctionVariance(mu, distribution);
        z = eta + (y - mu) .* derivee;
        w = poids ./ max(variance .* derivee .^ 2, eps);
        racine = sqrt(w);
        betaNouveau = (A .* repmat(racine, 1, p)) \ (z .* racine);
        if max(abs(betaNouveau - beta)) < 1e-10 * max(1, max(abs(betaNouveau)))
            beta = betaNouveau;
            break;
        end
        beta = betaNouveau;
        eta = A * beta;
        mu = lienInverse(eta, lien);
    end
    % Écarts types : la matrice de covariance asymptotique est l'inverse
    % de l'information de Fisher.
    derivee = deriveeLien(mu, lien);
    variance = fonctionVariance(mu, distribution);
    w = poids ./ max(variance .* derivee .^ 2, eps);
    information = A.' * (A .* repmat(w, 1, p));
    covariance = pinv(information);
    dispersion = 1;
    if any(strcmp(distribution, {'normal', 'gamma', 'inverse gaussian'}))
        residusPearson = (y - mu) ./ sqrt(max(variance, eps));
        dispersion = sum(poids .* residusPearson .^ 2) / max(n - p, 1);
        covariance = covariance * dispersion;
    end
    erreurs = sqrt(max(diag(covariance), 0));
    t = beta ./ max(erreurs, eps);
    pValeur = 2 * (1 - tcdf(abs(t), max(n - p, 1)));
    deviance = devianceGlm(y, mu, distribution, poids);
    logv = logVraisemblance(y, mu, distribution, poids, dispersion);
    modele = struct('Coefficients', beta, 'SE', erreurs, 'tStat', t, ...
                    'pValue', pValeur, 'Fitted', mu, 'Residuals', y - mu, ...
                    'Deviance', deviance, 'Dispersion', dispersion, ...
                    'LogLikelihood', logv, 'AIC', -2 * logv + 2 * p, ...
                    'BIC', -2 * logv + p * log(n), 'NumObservations', n, ...
                    'Distribution', distribution, 'Link', lien, ...
                    'DFE', max(n - p, 0), 'Intercept', avecConstante);
end

function nom = lienCanonique(distribution)
    switch distribution
        case 'normal',            nom = 'identity';
        case 'binomial',          nom = 'logit';
        case 'poisson',           nom = 'log';
        case 'gamma',             nom = 'reciprocal';
        case 'inverse gaussian',  nom = 'reciprocal';
        otherwise
            error('stats:fitglm:Distribution', 'Loi inconnue : %s.', distribution);
    end
end

function mu = departGlm(y, distribution, poids)
    switch distribution
        case 'binomial'
            mu = (y .* poids + 0.5) ./ (poids + 1);
        case 'poisson'
            mu = y + 0.25;
        case {'gamma', 'inverse gaussian'}
            mu = max(y, eps);
        otherwise
            mu = y;
    end
end

function eta = appliquerLien(mu, lien)
    switch lien
        case 'identity',   eta = mu;
        case 'log',        eta = log(max(mu, eps));
        case 'logit',      eta = log(mu ./ max(1 - mu, eps));
        case 'probit',     eta = norminv(min(max(mu, eps), 1 - eps));
        case 'loglog',     eta = log(-log(min(max(mu, eps), 1 - eps)));
        case 'reciprocal', eta = 1 ./ max(mu, eps);
        otherwise
            error('stats:fitglm:Lien', 'Lien inconnu : %s.', lien);
    end
end

function mu = lienInverse(eta, lien)
    switch lien
        case 'identity',   mu = eta;
        case 'log',        mu = exp(eta);
        case 'logit',      mu = 1 ./ (1 + exp(-eta));
        case 'probit',     mu = normcdf(eta);
        case 'loglog',     mu = exp(-exp(eta));
        case 'reciprocal', mu = 1 ./ eta;
    end
end

function d = deriveeLien(mu, lien)
% d(eta)/d(mu), ce qui pondère la réponse linéarisée.
    switch lien
        case 'identity',   d = ones(size(mu));
        case 'log',        d = 1 ./ max(mu, eps);
        case 'logit',      d = 1 ./ max(mu .* (1 - mu), eps);
        case 'probit',     d = 1 ./ max(normpdf(norminv(min(max(mu, eps), 1 - eps))), eps);
        case 'loglog'
            m = min(max(mu, eps), 1 - eps);
            d = -1 ./ max(m .* log(m), eps);
        case 'reciprocal', d = -1 ./ max(mu .^ 2, eps);
    end
end

function v = fonctionVariance(mu, distribution)
    switch distribution
        case 'normal',           v = ones(size(mu));
        case 'binomial',         v = max(mu .* (1 - mu), eps);
        case 'poisson',          v = max(mu, eps);
        case 'gamma',            v = max(mu .^ 2, eps);
        case 'inverse gaussian', v = max(mu .^ 3, eps);
    end
end

function d = devianceGlm(y, mu, distribution, poids)
    switch distribution
        case 'normal'
            d = sum(poids .* (y - mu) .^ 2);
        case 'binomial'
            terme = zeros(size(y));
            positif = y > 0;
            terme(positif) = y(positif) .* log(y(positif) ./ max(mu(positif), eps));
            reste = y < 1;
            terme(reste) = terme(reste) + ...
                (1 - y(reste)) .* log((1 - y(reste)) ./ max(1 - mu(reste), eps));
            d = 2 * sum(poids .* terme);
        case 'poisson'
            terme = zeros(size(y));
            positif = y > 0;
            terme(positif) = y(positif) .* log(y(positif) ./ max(mu(positif), eps));
            d = 2 * sum(poids .* (terme - (y - mu)));
        case 'gamma'
            d = 2 * sum(poids .* (-log(max(y, eps) ./ max(mu, eps)) + (y - mu) ./ max(mu, eps)));
        case 'inverse gaussian'
            d = sum(poids .* (y - mu) .^ 2 ./ max(y .* mu .^ 2, eps));
    end
end

function logv = logVraisemblance(y, mu, distribution, poids, dispersion)
    n = numel(y);
    switch distribution
        case 'normal'
            sigma2 = sum(poids .* (y - mu) .^ 2) / n;
            logv = -0.5 * n * (log(2 * pi * max(sigma2, eps)) + 1);
        case 'binomial'
            logv = sum(poids .* (y .* log(max(mu, eps)) + (1 - y) .* log(max(1 - mu, eps))));
        case 'poisson'
            logv = sum(poids .* (y .* log(max(mu, eps)) - mu - gammaln(y + 1)));
        otherwise
            logv = -0.5 * devianceGlm(y, mu, distribution, poids) / max(dispersion, eps);
    end
end
