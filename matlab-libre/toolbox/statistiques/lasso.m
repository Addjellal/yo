function [B, info] = lasso(X, y, varargin)
%LASSO Régression pénalisée par la norme 1.
%   B = LASSO(X,Y) ajuste Y = X*B en pénalisant la somme des valeurs
%   absolues des coefficients. La pénalité met exactement à zéro les
%   coefficients inutiles : le modèle choisit ses variables en même temps
%   qu'il les ajuste, ce que la régression ordinaire ne fait pas.
%
%   B a une colonne par valeur de la pénalité ; par défaut, cent valeurs
%   décroissantes depuis celle qui annule tous les coefficients.
%
%   [B,INFO] = LASSO(...) rend une structure décrivant chaque ajustement :
%   Lambda, Alpha, Intercept, DF (nombre de coefficients non nuls) et MSE.
%
%   LASSO(...,'Lambda',L) impose les pénalités,
%   LASSO(...,'Alpha',A) mélange norme 1 et norme 2 — A = 1 donne le
%   lasso, A proche de 0 la régression d'arête, entre les deux le filet
%   élastique.
%   LASSO(...,'NumLambda',N), 'LambdaRatio',R, 'Standardize',TF,
%   'MaxIter',N, 'RelTol',T règlent le reste.
%
%   Exemple :
%      rng(1);
%      X = randn(100, 10);
%      y = X(:, 1) * 3 - X(:, 2) * 2 + 0.1 * randn(100, 1);
%      [B, info] = lasso(X, y, 'Lambda', 0.1);
%      nnz(B)        % deux coefficients survivent
%
%   Voir aussi RIDGE, REGRESS, FITLM, STEPWISEFIT, LASSOGLM.
    X = double(X);
    y = double(y(:));
    [n, p] = size(X);
    alpha = 1;
    lambda = [];
    nombreLambda = 100;
    rapport = [];
    standardiser = true;
    maxIter = 1e4;
    tolerance = 1e-4;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'lambda',      lambda = double(varargin{k+1});
            case 'alpha',       alpha = double(varargin{k+1});
            case 'numlambda',   nombreLambda = round(varargin{k+1});
            case 'lambdaratio', rapport = double(varargin{k+1});
            case 'standardize', standardiser = logical(varargin{k+1});
            case 'maxiter',     maxIter = round(varargin{k+1});
            case 'reltol',      tolerance = double(varargin{k+1});
            case {'cv', 'mcreps', 'predictornames', 'weights', 'options'}
                % Acceptées et sans effet : la validation croisée
                % s'écrit avec CVPARTITION.
            otherwise
                error('stats:lasso:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if alpha <= 0 || alpha > 1
        error('stats:lasso:Alpha', 'Alpha doit être dans ]0, 1].');
    end
    % Centrage et réduction : la pénalité n'a de sens que si les colonnes
    % sont comparables, et l'ordonnée à l'origine ne doit pas être punie.
    moyenneX = mean(X, 1);
    Xc = X - repmat(moyenneX, n, 1);
    if standardiser
        echelle = sqrt(sum(Xc .^ 2, 1) / n);
        echelle(echelle == 0) = 1;
    else
        echelle = ones(1, p);
    end
    Xc = Xc ./ repmat(echelle, n, 1);
    moyenneY = mean(y);
    yc = y - moyenneY;
    if isempty(lambda)
        lambdaMax = max(abs(Xc.' * yc)) / (n * alpha);
        if isempty(rapport)
            if n > p
                rapport = 1e-4;
            else
                rapport = 1e-2;
            end
        end
        lambda = exp(linspace(log(lambdaMax), log(lambdaMax * rapport), nombreLambda));
    end
    lambda = sort(double(lambda(:)).', 'descend');
    B = zeros(p, numel(lambda));
    intercepts = zeros(1, numel(lambda));
    df = zeros(1, numel(lambda));
    mse = zeros(1, numel(lambda));
    normes = sum(Xc .^ 2, 1) / n;
    beta = zeros(p, 1);
    for j = 1:numel(lambda)
        l = lambda(j);
        % Descente par coordonnées : à chaque pas, un seul coefficient
        % bouge, et son optimum s'écrit en clair par le seuillage doux.
        for iteration = 1:maxIter
            changementMax = 0;
            residu = yc - Xc * beta;
            for i = 1:p
                if normes(i) == 0
                    continue;
                end
                partiel = residu + Xc(:, i) * beta(i);
                rho = Xc(:, i).' * partiel / n;
                nouveau = seuillageDoux(rho, l * alpha) / (normes(i) + l * (1 - alpha));
                if nouveau ~= beta(i)
                    residu = partiel - Xc(:, i) * nouveau;
                    changementMax = max(changementMax, abs(nouveau - beta(i)));
                    beta(i) = nouveau;
                end
            end
            if changementMax < tolerance * max(1, max(abs(beta)))
                break;
            end
        end
        % Retour aux unités d'origine.
        coefficients = beta ./ echelle.';
        B(:, j) = coefficients;
        intercepts(j) = moyenneY - moyenneX * coefficients;
        df(j) = sum(abs(coefficients) > 0);
        residuFinal = y - X * coefficients - intercepts(j);
        mse(j) = sum(residuFinal .^ 2) / n;
    end
    info = struct('Intercept', intercepts, 'Lambda', lambda, 'Alpha', alpha, ...
                  'DF', df, 'MSE', mse, 'PredictorNames', {{}}, ...
                  'Lambda1SE', lambda(end), 'LambdaMinMSE', lambda(mse == min(mse)));
end

function s = seuillageDoux(x, seuil)
%SEUILLAGEDOUX L'optimum d'un problème à un coefficient pénalisé en |b|.
    s = sign(x) * max(abs(x) - seuil, 0);
end
