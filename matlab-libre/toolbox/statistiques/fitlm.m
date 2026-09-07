function modele = fitlm(X, y)
%FITLM Modèle linéaire avec ordonnée à l'origine.
%   M = FITLM(X,Y) ajuste Y = b0 + X*b et rend une structure décrivant le
%   modèle : coefficients, R2, résidus, écarts types.
%
%   Exemple :
%      rng(1);
%      x = (1:50)';
%      m = fitlm(x, 2 + 3 * x + randn(50, 1));
%      abs(m.Coefficients(2) - 3) < 0.1
    X = X(:, :);
    y = y(:);
    A = [ones(size(X, 1), 1), X];
    [b, bint, r, ~, stats] = regress(y, A);
    modele = struct('Coefficients', b, 'CoefficientCI', bint, ...
                    'Residuals', r, 'Rsquared', stats(1), ...
                    'NumObservations', numel(y), 'Formula', 'y ~ 1 + x');
end
