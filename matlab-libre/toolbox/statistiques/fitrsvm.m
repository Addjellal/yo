function modele = fitrsvm(X, y, varargin)
%FITRSVM Régression par vecteurs de support.
%   M = FITRSVM(X,Y) ajuste une régression qui ne pénalise que les
%   erreurs dépassant une marge EPSILON : à l'intérieur du tube, un point
%   ne coûte rien. C'est ce qui rend la méthode peu sensible aux points
%   aberrants.
%
%   Les options sont celles de FITCSVM, plus 'Epsilon',E qui règle la
%   demi-largeur du tube — un dixième de l'écart type de Y par défaut.
%
%   L'optimisation ramène le problème dual de la régression à celui d'une
%   classification à 2N points : c'est la formulation classique, où le
%   multiplicateur de chaque point se dédouble en une part au-dessus et
%   une part au-dessous du tube.
%
%   Exemple :
%      rng(1);
%      X = linspace(-3, 3, 60)';
%      y = sin(X) + 0.05 * randn(60, 1);
%      m = fitrsvm(X, y, 'KernelFunction', 'rbf', 'KernelScale', 1);
%      max(abs(predict(m, X) - y)) < 0.5
%
%   Voir aussi FITCSVM, PREDICT, FITRGP, FITLM.
    X = double(X);
    y = double(y(:));
    options = lireOptionsSvm(varargin{:});
    if isempty(options.Epsilon)
        options.Epsilon = std(y) / 10;
        if options.Epsilon == 0
            options.Epsilon = 1e-3;
        end
    end
    [X, centre, echelle] = standardiserSvm(X, options.Standardize);
    n = size(X, 1);
    K = noyauSvm(X, X, options);
    % Régression epsilon : chaque point se dédouble, une part au-dessus
    % du tube et une part au-dessous. Le dual devient celui d'une
    % classification sur 2N points, que SMO sait résoudre.
    Kdouble = [K, -K; -K, K];
    cibleDouble = [ones(n, 1); -ones(n, 1)];
    % Le second membre porte epsilon : on le fait entrer par une cible
    % décalée, ce qui revient à minimiser la même chose.
    yDouble = [y - options.Epsilon; -(y + options.Epsilon)];
    alpha = smoRegression(Kdouble, yDouble, options.BoxConstraint, options.Tolerance, ...
                          options.MaxIter);
    coefficients = alpha(1:n) - alpha((n + 1):end);
    support = abs(coefficients) > options.Tolerance;
    biais = mean(y(support) - K(support, :) * coefficients);
    if isnan(biais)
        biais = mean(y);
    end
    modele = struct('type', 'svm-regression', 'Classes', [], ...
                    'Alpha', abs(coefficients(support)), ...
                    'Cible', sign(coefficients(support)), ...
                    'SupportVectors', X(support, :), 'Bias', biais, ...
                    'Options', options, 'Centre', centre, 'Echelle', echelle, ...
                    'Beta', [], 'Regression', true, 'NumObservations', n);
    if strcmp(options.KernelFunction, 'linear')
        modele.Beta = (coefficients(support).' * X(support, :)).';
    end
end

function alpha = smoRegression(K, cible, C, tolerance, maxIter)
% Descente par coordonnées sur le dual : à chaque pas, un multiplicateur
% se place à son optimum, borné dans [0, C]. C'est plus simple que SMO
% et suffit ici, la contrainte d'égalité étant absorbée par le biais
% calculé ensuite.
    n = numel(cible);
    alpha = zeros(n, 1);
    diagonale = max(diag(K), eps);
    for iteration = 1:maxIter
        changement = 0;
        gradient = K * alpha - cible;
        for i = 1:n
            pas = -gradient(i) / diagonale(i);
            nouveau = min(max(alpha(i) + pas, 0), C);
            if abs(nouveau - alpha(i)) > 1e-12
                gradient = gradient + K(:, i) * (nouveau - alpha(i));
                changement = max(changement, abs(nouveau - alpha(i)));
                alpha(i) = nouveau;
            end
        end
        if changement < tolerance
            break;
        end
    end
end
