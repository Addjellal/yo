function modele = fitclinear(X, y, varargin)
%FITCLINEAR Classifieur linéaire pour données de grande dimension.
%   M = FITCLINEAR(X,Y) ajuste un classifieur binaire linéaire par
%   descente de gradient sur une perte régularisée. À la différence de
%   FITCSVM, rien n'est stocké des données : le modèle tient dans un
%   vecteur de poids, ce qui convient aux problèmes à beaucoup de
%   variables.
%
%   FITCLINEAR(...,'Learner','svm') minimise la perte charnière
%   (défaut) ; 'logistic' minimise la perte logistique et rend des
%   probabilités.
%   FITCLINEAR(...,'Regularization','ridge') pénalise la norme 2
%   (défaut) ; 'lasso' pénalise la norme 1 et met des poids à zéro.
%   FITCLINEAR(...,'Lambda',L) règle la pénalité, 'PassLimit',N le
%   nombre de passages, 'FitBias',false retire le biais.
%
%   Exemple :
%      rng(1);
%      X = [randn(100, 20); randn(100, 20) + 0.8];
%      y = [-ones(100, 1); ones(100, 1)];
%      m = fitclinear(X, y);
%      mean(predict(m, X) == y)
%
%   Voir aussi PREDICT, FITRLINEAR, FITCSVM, LASSO, FITGLM.
    X = double(X);
    y = y(:);
    classes = unique(y);
    if numel(classes) ~= 2
        error('stats:fitclinear:DeuxClasses', ...
              'FITCLINEAR ne traite que deux classes ; voir FITCECOC.');
    end
    cible = ones(size(y));
    cible(y == classes(1)) = -1;
    options = lireOptionsLineaire(size(X, 1), varargin{:});
    [poids, biais] = descenteLineaire(X, cible, options, false);
    modele = struct('type', 'lineaire', 'Classes', classes, 'Beta', poids, ...
                    'Bias', biais, 'Learner', options.Learner, ...
                    'Regression', false, 'NumObservations', numel(y));
end
