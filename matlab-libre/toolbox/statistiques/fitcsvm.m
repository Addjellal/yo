function modele = fitcsvm(X, y, varargin)
%FITCSVM Machine à vecteurs de support, classification binaire.
%   M = FITCSVM(X,Y) cherche la frontière qui sépare les deux classes en
%   laissant la plus large marge possible. Y ne doit porter que deux
%   valeurs.
%
%   FITCSVM(...,'KernelFunction',K) choisit le noyau : 'linear' (défaut),
%   'rbf' (ou 'gaussian'), 'polynomial'.
%   FITCSVM(...,'BoxConstraint',C) règle la tolérance aux points mal
%   classés — C grand exige une séparation stricte, C petit accepte des
%   erreurs pour élargir la marge.
%   FITCSVM(...,'KernelScale',S) et 'PolynomialOrder',D règlent le noyau.
%   FITCSVM(...,'Standardize',true) centre et réduit les colonnes.
%
%   L'optimisation est celle de Platt — SMO — sur le problème dual :
%   deux multiplicateurs bougent à la fois, ce qui respecte la contrainte
%   d'égalité sans passer par un solveur général.
%
%   PREDICT applique le modèle ; DISCARDSUPPORTVECTORS allège un modèle
%   linéaire dont on n'a plus besoin des points.
%
%   Exemple :
%      rng(1);
%      X = [randn(40, 2); randn(40, 2) + 3];
%      y = [-ones(40, 1); ones(40, 1)];
%      m = fitcsvm(X, y);
%      mean(predict(m, X) == y)
%
%   Voir aussi PREDICT, FITRSVM, FITCECOC, DISCARDSUPPORTVECTORS, FITCNB.
    X = double(X);
    y = y(:);
    classes = unique(y);
    if numel(classes) ~= 2
        error('stats:fitcsvm:DeuxClasses', ...
              'FITCSVM ne traite que deux classes ; voir FITCECOC.');
    end
    cible = ones(size(y));
    cible(y == classes(1)) = -1;
    options = lireOptionsSvm(varargin{:});
    [X, centre, echelle] = standardiserSvm(X, options.Standardize);
    K = noyauSvm(X, X, options);
    [alpha, biais] = resoudreSmo(K, cible, options.BoxConstraint, options.Tolerance, ...
                                 options.MaxIter);
    support = alpha > options.Tolerance;
    modele = struct('type', 'svm', 'Classes', classes, 'Alpha', alpha(support), ...
                    'Cible', cible(support), 'SupportVectors', X(support, :), ...
                    'Bias', biais, 'Options', options, 'Centre', centre, ...
                    'Echelle', echelle, 'Beta', [], 'Regression', false, ...
                    'NumObservations', numel(y));
    if strcmp(options.KernelFunction, 'linear')
        % Un noyau linéaire a un vecteur de poids explicite : c'est lui
        % qui permet de se passer des points.
        modele.Beta = (modele.Alpha .* modele.Cible).' * modele.SupportVectors;
        modele.Beta = modele.Beta(:);
    end
end
