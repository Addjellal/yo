function [B, dev, stats] = mnrfit(X, Y, varargin)
%MNRFIT Régression logistique multinomiale.
%   B = MNRFIT(X,Y) ajuste un modèle qui prédit la catégorie de chaque
%   observation. Y donne la catégorie — un entier de 1 à K —, ou bien les
%   effectifs observés dans chaque catégorie, une colonne par catégorie.
%
%   B a K-1 colonnes : les coefficients de chaque catégorie face à la
%   dernière, qui sert de référence. La première ligne est l'ordonnée à
%   l'origine.
%
%   [B,DEV,STATS] = MNRFIT(...) rend la déviance et une structure
%   d'écarts types, de statistiques t et de p-valeurs.
%
%   MNRFIT(...,'Model','nominal') — le seul modèle traité — et
%   'Interactions', acceptés pour la compatibilité.
%
%   L'ajustement est par la méthode de Newton sur la log-vraisemblance,
%   avec division du pas quand elle ne croît pas.
%
%   Exemple :
%      rng(1);
%      X = randn(300, 2);
%      score = [X * [2; -1], X * [-1; 2], zeros(300, 1)];
%      [~, y] = max(score + 0.5 * randn(300, 3), [], 2);
%      B = mnrfit(X, y);
%
%   Voir aussi MNRVAL, FITGLM, FITCECOC, GLMFIT.
    X = double(X);
    if isvector(X) && size(X, 1) == 1
        X = X(:);
    end
    n = size(X, 1);
    [Y, k] = comptesCategories(Y, n);
    A = [ones(n, 1), X];
    p = size(A, 2);
    total = sum(Y, 2);
    beta = zeros(p, k - 1);
    logvPrecedente = -inf;
    for iteration = 1:200
        P = probabilites(A, beta);
        logv = sum(sum(Y .* log(max(P, eps))));
        if logv < logvPrecedente - 1e-12
            % Le pas a fait baisser la vraisemblance : on revient en
            % arrière de moitié plutôt que de diverger.
            beta = beta - pas / 2;
            pas = pas / 2;
            continue;
        end
        gradient = zeros(p * (k - 1), 1);
        hessienne = zeros(p * (k - 1));
        for j = 1:(k - 1)
            lignes = ((j - 1) * p + 1):(j * p);
            gradient(lignes) = A.' * (Y(:, j) - total .* P(:, j));
            for m = 1:(k - 1)
                colonnes = ((m - 1) * p + 1):(m * p);
                if j == m
                    poids = total .* P(:, j) .* (1 - P(:, j));
                else
                    poids = -total .* P(:, j) .* P(:, m);
                end
                hessienne(lignes, colonnes) = -A.' * (A .* repmat(poids, 1, p));
            end
        end
        if max(abs(gradient)) < 1e-10
            break;
        end
        pasVecteur = -pinv(hessienne) * gradient;
        pas = reshape(pasVecteur, p, k - 1);
        beta = beta + pas;
        logvPrecedente = logv;
    end
    B = beta;
    P = probabilites(A, beta);
    dev = -2 * sum(sum(Y .* log(max(P, eps))));
    if nargout < 3
        return;
    end
    % Écarts types : l'inverse de l'information observée, qui est
    % l'opposé de la hessienne au point trouvé.
    information = zeros(p * (k - 1));
    for j = 1:(k - 1)
        lignes = ((j - 1) * p + 1):(j * p);
        for m = 1:(k - 1)
            colonnes = ((m - 1) * p + 1):(m * p);
            if j == m
                poids = total .* P(:, j) .* (1 - P(:, j));
            else
                poids = -total .* P(:, j) .* P(:, m);
            end
            information(lignes, colonnes) = A.' * (A .* repmat(poids, 1, p));
        end
    end
    covariance = pinv(information);
    erreurs = reshape(sqrt(max(diag(covariance), 0)), p, k - 1);
    t = B ./ max(erreurs, eps);
    stats = struct('beta', B, 'se', erreurs, 't', t, ...
                   'p', 2 * (1 - normcdf(abs(t))), 'dfe', n - p * (k - 1), ...
                   'covb', covariance);
end

function P = probabilites(A, beta)
% Le modèle nominal : la dernière catégorie sert de référence, son
% score est nul.
    scores = [A * beta, zeros(size(A, 1), 1)];
    scores = scores - repmat(max(scores, [], 2), 1, size(scores, 2));
    exponentielles = exp(scores);
    P = exponentielles ./ repmat(sum(exponentielles, 2), 1, size(scores, 2));
end

function [Y, k] = comptesCategories(Y, n)
% Y donné en catégories devient une matrice d'indicatrices.
    Y = double(Y);
    if isvector(Y) && numel(Y) == n
        categories = round(Y(:));
        k = max(categories);
        if k < 2
            error('stats:mnrfit:Categories', 'Il faut au moins deux catégories.');
        end
        indicatrices = zeros(n, k);
        for i = 1:n
            indicatrices(i, categories(i)) = 1;
        end
        Y = indicatrices;
    else
        k = size(Y, 2);
    end
end
