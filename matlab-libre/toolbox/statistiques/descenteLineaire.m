function [poids, biais] = descenteLineaire(X, y, options, regression)
%DESCENTELINEAIRE Descente de gradient d'un modèle linéaire régularisé.
%   Le pas décroît en 1/(lambda*t), comme dans les méthodes de gradient
%   moyennées : c'est ce qui garantit la convergence sans réglage.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [n, p] = size(X);
    poids = zeros(p, 1);
    biais = 0;
    lambda = max(options.Lambda, 1e-12);
    for passage = 1:options.PassLimit
        marge = X * poids + biais;
        switch options.Learner
            case 'svm'
                actifs = (y .* marge) < 1;
                gradient = -(X.' * (y .* actifs)) / n;
                gradientBiais = -sum(y .* actifs) / n;
            case 'logistic'
                sigma = 1 ./ (1 + exp(y .* marge));
                gradient = -(X.' * (y .* sigma)) / n;
                gradientBiais = -sum(y .* sigma) / n;
            case 'moindrescarres'
                residu = marge - y;
                gradient = (X.' * residu) / n;
                gradientBiais = sum(residu) / n;
            case 'epsilon'
                residu = marge - y;
                actifs = abs(residu) > options.Epsilon;
                gradient = (X.' * (sign(residu) .* actifs)) / n;
                gradientBiais = sum(sign(residu) .* actifs) / n;
            otherwise
                error('stats:fitclinear:Learner', ...
                      'Apprenant inconnu : %s.', options.Learner);
        end
        pas = 1 / (lambda * passage);
        if strcmp(options.Regularization, 'lasso')
            poids = poids - pas * gradient;
            % Seuillage doux : c'est la partie proximale de la pénalité
            % en norme 1, celle qui met vraiment des poids à zéro.
            poids = sign(poids) .* max(abs(poids) - pas * lambda, 0);
        else
            poids = poids - pas * (gradient + lambda * poids);
        end
        if options.FitBias
            biais = biais - pas * gradientBiais;
        end
        % Projection classique de Pegasos : elle borne la norme et évite
        % les premiers pas démesurés.
        norme = norm(poids);
        limite = 1 / sqrt(lambda);
        if norme > limite
            poids = poids * (limite / norme);
        end
    end
end
