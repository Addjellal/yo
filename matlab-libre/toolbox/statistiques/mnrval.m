function P = mnrval(B, X, varargin)
%MNRVAL Probabilités prédites par un modèle multinomial.
%   P = MNRVAL(B,X) rend, pour chaque ligne de X, la probabilité de
%   chaque catégorie sous le modèle ajusté par MNRFIT. P a une colonne de
%   plus que B : la dernière est celle de la catégorie de référence.
%
%   Exemple :
%      rng(1);
%      X = [randn(60, 1); randn(60, 1) + 3; randn(60, 1) + 6];
%      y = [ones(60, 1); 2 * ones(60, 1); 3 * ones(60, 1)];
%      B = mnrfit(X, y);
%      P = mnrval(B, X);
%      [~, predites] = max(P, [], 2);
%      max(abs(sum(P, 2) - 1)) < 1e-10    % 1 : les probabilites somment a un
%
%   Voir aussi MNRFIT, FITGLM.
    X = double(X);
    if isvector(X) && size(X, 1) == 1
        X = X(:);
    end
    A = [ones(size(X, 1), 1), X];
    scores = [A * B, zeros(size(A, 1), 1)];
    scores = scores - repmat(max(scores, [], 2), 1, size(scores, 2));
    exponentielles = exp(scores);
    P = exponentielles ./ repmat(sum(exponentielles, 2), 1, size(scores, 2));
end
