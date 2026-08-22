function modele = fitlm(X, y)
%FITLM Modèle linéaire avec ordonnée à l'origine.
%   M = FITLM(X,Y) ajuste Y = b0 + X*b et rend une structure décrivant le
%   modèle : coefficients, R2, résidus, écarts types.
    X = X(:, :);
    y = y(:);
    A = [ones(size(X, 1), 1), X];
    [b, bint, r, ~, stats] = regress(y, A);
    modele = struct('Coefficients', b, 'CoefficientCI', bint, ...
                    'Residuals', r, 'Rsquared', stats(1), ...
                    'NumObservations', numel(y), 'Formula', 'y ~ 1 + x');
end
