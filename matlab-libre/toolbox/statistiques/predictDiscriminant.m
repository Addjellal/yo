function [etiquettes, scores] = predictDiscriminant(modele, X)
%PREDICTDISCRIMINANT Prédiction d'une analyse discriminante.
%   [Y,S] = PREDICTDISCRIMINANT(M,X) rend la classe la plus probable et,
%   dans S, les probabilités a posteriori — une colonne par classe.
%
%   Le score d'une classe est le logarithme de sa densité gaussienne
%   ajouté à celui de sa probabilité a priori :
%
%      s_c(x) = log P(c) - 1/2 log|Sigma_c| - 1/2 (x-mu_c)' inv(Sigma_c) (x-mu_c)
%
%   Les scores sont ramenés à des probabilités par l'exponentielle
%   normalisée, en soustrayant d'abord leur maximum : sans cela
%   l'exponentielle déborderait dès que les classes sont bien séparées.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
%   où PREDICT est une méthode du modèle.
%
%   Voir aussi FITCDISCR, PREDICT.
    X = double(X);
    k = numel(modele.Classes);
    n = size(X, 1);
    scoresLog = zeros(n, k);
    for c = 1:k
        S = modele.Sigma{c};
        centre = X - modele.Mu(c, :);
        % La résolution par « \ » évite de former l'inverse.
        quadratique = sum((centre / S) .* centre, 2);
        [~, positif] = chol(S);
        if positif == 0
            logDeterminant = 2 * sum(log(diag(chol(S))));
        else
            logDeterminant = log(max(abs(det(S)), realmin));
        end
        scoresLog(:, c) = log(max(modele.Prior(c), realmin)) ...
                          - 0.5 * logDeterminant - 0.5 * quadratique;
    end
    [~, choisi] = max(scoresLog, [], 2);
    classes = modele.Classes;
    if iscell(classes)
        etiquettes = classes(choisi);
    else
        etiquettes = classes(choisi);
    end
    if nargout > 1
        decale = scoresLog - max(scoresLog, [], 2);
        poids = exp(decale);
        scores = poids ./ sum(poids, 2);
    end
end
