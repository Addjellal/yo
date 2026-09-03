function modele = fitgmdist(X, k, varargin)
%FITGMDIST Ajuste un mélange gaussien par l'algorithme EM.
%   M = FITGMDIST(X,K) cherche K gaussiennes dont le mélange explique au
%   mieux X. L'algorithme alterne deux pas : estimer à quelle composante
%   chaque point appartient, puis réestimer les composantes d'après ces
%   appartenances. La vraisemblance ne peut que croître.
%
%   FITGMDIST(...,'Replicates',R) relance R fois depuis des départs
%   différents et garde le meilleur — EM converge vers un maximum local,
%   et le départ compte.
%   FITGMDIST(...,'CovarianceType','diagonal') suppose les variables
%   indépendantes dans chaque composante,
%   'SharedCovariance',true impose une covariance commune,
%   'RegularizationValue',R ajoute R à la diagonale, ce qui évite les
%   composantes qui s'effondrent sur un point,
%   'Start',S impose les appartenances de départ,
%   'Options',statset('MaxIter',N,'TolFun',T) règle l'arrêt.
%
%   Exemple :
%      rng(1);
%      X = [randn(200, 2); randn(200, 2) + 4];
%      m = fitgmdist(X, 2);
%      m.ComponentProportion
%
%   Voir aussi GMDISTRIBUTION, CLUSTER, KMEANS, PDF, RANDOM.
    X = double(X);
    [n, d] = size(X);
    k = round(k);
    repliques = 1;
    typeCovariance = 'full';
    partagee = false;
    regularisation = 0;
    maxIter = 100;
    tolerance = 1e-6;
    depart = [];
    j = 1;
    while j + 1 <= numel(varargin)
        switch lower(char(varargin{j}))
            case 'replicates',          repliques = round(varargin{j+1});
            case 'covariancetype',      typeCovariance = lower(char(varargin{j+1}));
            case 'sharedcovariance',    partagee = logical(varargin{j+1});
            case 'regularizationvalue', regularisation = double(varargin{j+1});
            case 'start',               depart = varargin{j+1};
            case 'options'
                o = varargin{j+1};
                if isstruct(o)
                    if isfield(o, 'MaxIter') && ~isempty(o.MaxIter)
                        maxIter = round(o.MaxIter);
                    end
                    if isfield(o, 'TolFun') && ~isempty(o.TolFun)
                        tolerance = double(o.TolFun);
                    end
                end
            otherwise
                error('stats:fitgmdist:Option', 'Option inconnue : %s.', char(varargin{j}));
        end
        j = j + 2;
    end
    diagonale = strncmp(typeCovariance, 'd', 1);
    meilleure = -inf;
    modele = [];
    for essai = 1:max(1, repliques)
        [mu, sigma, poids] = departMelange(X, k, depart, diagonale, regularisation);
        logvPrecedente = -inf;
        converge = false;
        iteration = 0;
        for iteration = 1:maxIter
            % Pas E : la responsabilité de chaque composante pour chaque
            % point, calculée dans les logarithmes.
            logDensites = zeros(n, k);
            for c = 1:k
                logDensites(:, c) = log(max(poids(c), eps)) + ...
                    logGaussienne(X, mu(c, :), covariance(sigma, c, diagonale, d), ...
                                  regularisation);
            end
            maximum = max(logDensites, [], 2);
            exponentielles = exp(logDensites - repmat(maximum, 1, k));
            sommes = sum(exponentielles, 2);
            responsabilites = exponentielles ./ repmat(sommes, 1, k);
            logv = sum(maximum + log(sommes));
            if abs(logv - logvPrecedente) < tolerance * max(1, abs(logv))
                converge = true;
                break;
            end
            logvPrecedente = logv;
            % Pas M : les composantes se réestiment comme si les
            % responsabilités étaient des effectifs.
            effectifs = sum(responsabilites, 1);
            poids = effectifs / n;
            for c = 1:k
                mu(c, :) = (responsabilites(:, c).' * X) / max(effectifs(c), eps);
                ecarts = X - repmat(mu(c, :), n, 1);
                pondere = ecarts .* repmat(responsabilites(:, c), 1, d);
                if diagonale
                    sigma(1, :, c) = sum(pondere .* ecarts, 1) / max(effectifs(c), eps);
                else
                    sigma(:, :, c) = (pondere.' * ecarts) / max(effectifs(c), eps);
                end
            end
            if partagee
                commune = zeros(size(sigma(:, :, 1)));
                for c = 1:k
                    commune = commune + poids(c) * sigma(:, :, c);
                end
                for c = 1:k
                    sigma(:, :, c) = commune;
                end
            end
        end
        if logv > meilleure
            meilleure = logv;
            modele = gmdistribution(mu, sigma, poids);
            modele.NLogL = -logv;
            modele.Converged = converge;
            modele.NumIterations = iteration;
            modele.SharedCovariance = partagee;
            modele.DiagonalCovariance = diagonale;
            modele.RegularizationValue = regularisation;
            modele.AIC = 2 * nombreParametres(k, d, diagonale, partagee) - 2 * logv;
            modele.BIC = nombreParametres(k, d, diagonale, partagee) * log(n) - 2 * logv;
        end
    end
end

function [mu, sigma, poids] = departMelange(X, k, depart, diagonale, regularisation)
% Le départ : k-means quand rien n'est imposé, ce qui donne des
% composantes déjà séparées.
    [n, d] = size(X);
    if isempty(depart)
        indices = kmeans(X, k);
    elseif isnumeric(depart) && numel(depart) == n
        indices = round(depart(:));
    else
        indices = randi(k, n, 1);
    end
    mu = zeros(k, d);
    if diagonale
        sigma = zeros(1, d, k);
    else
        sigma = zeros(d, d, k);
    end
    poids = zeros(1, k);
    for c = 1:k
        bloc = X(indices == c, :);
        if isempty(bloc)
            bloc = X(randi(n), :);
        end
        mu(c, :) = mean(bloc, 1);
        poids(c) = size(bloc, 1) / n;
        if diagonale
            sigma(1, :, c) = max(var(bloc, 0, 1), regularisation + 1e-6);
        else
            if size(bloc, 1) > 1
                sigma(:, :, c) = cov(bloc) + (regularisation + 1e-6) * eye(d);
            else
                sigma(:, :, c) = eye(d);
            end
        end
    end
    poids = poids / sum(poids);
end

function S = covariance(sigma, c, diagonale, d)
    if diagonale
        S = diag(reshape(sigma(1, :, c), 1, d));
    else
        S = sigma(:, :, c);
    end
end

function l = logGaussienne(X, mu, S, regularisation)
% Densité gaussienne en logarithme, par Cholesky : c'est stable, et le
% déterminant s'y lit sans calcul séparé.
    d = size(X, 2);
    S = S + regularisation * eye(d);
    [R, defaut] = chol(S);
    if defaut ~= 0
        S = S + (1e-8 + abs(min(eig(S)))) * eye(d);
        R = chol(S);
    end
    ecarts = X - repmat(mu, size(X, 1), 1);
    resolu = ecarts / R;
    l = -0.5 * sum(resolu .^ 2, 2) - sum(log(diag(R))) - 0.5 * d * log(2 * pi);
end

function p = nombreParametres(k, d, diagonale, partagee)
    if diagonale
        parCovariance = d;
    else
        parCovariance = d * (d + 1) / 2;
    end
    if partagee
        total = parCovariance;
    else
        total = k * parCovariance;
    end
    p = (k - 1) + k * d + total;
end
