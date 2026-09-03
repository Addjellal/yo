function modele = fitrlinear(X, y, varargin)
%FITRLINEAR Régression linéaire pour données de grande dimension.
%   M = FITRLINEAR(X,Y) ajuste une régression linéaire par descente de
%   gradient sur une perte régularisée, sans former la matrice normale :
%   c'est ce qui la rend praticable quand les variables se comptent par
%   milliers.
%
%   FITRLINEAR(...,'Learner','leastsquares') minimise l'erreur
%   quadratique (défaut) ; 'svm' minimise la perte epsilon-insensible.
%   Les options 'Regularization', 'Lambda', 'PassLimit' et 'FitBias' sont
%   celles de FITCLINEAR.
%
%   Exemple :
%      rng(1);
%      X = randn(200, 10);
%      y = X * (1:10)' + randn(200, 1);
%      m = fitrlinear(X, y, 'Lambda', 1e-6);
%      corr(predict(m, X), y) > 0.99
%
%   Voir aussi PREDICT, FITCLINEAR, FITLM, LASSO, RIDGE.
    X = double(X);
    y = double(y(:));
    options = lireOptionsLineaire(size(X, 1), varargin{:});
    if strcmp(options.Learner, 'svm')
        options.Learner = 'epsilon';
    else
        options.Learner = 'moindrescarres';
    end
    [poids, biais] = descenteLineaire(X, y, options, true);
    modele = struct('type', 'lineaire', 'Classes', [], 'Beta', poids, ...
                    'Bias', biais, 'Learner', options.Learner, ...
                    'Regression', true, 'NumObservations', numel(y));
end
