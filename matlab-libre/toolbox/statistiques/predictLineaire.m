function [etiquettes, scores] = predictLineaire(modele, X)
%PREDICTLINEAIRE Prédiction d'un modèle linéaire de grande dimension.
%   Employer PREDICT ; cette fonction est le rouage qu'il appelle.
%
%   Exemple :
%      rng(1);
%      X = [randn(40, 2); randn(40, 2) + 3];
%      y = [ones(40, 1); 2 * ones(40, 1)];
%      mean(predictLineaire(fitclinear(X, y), X) == y) > 0.8
    X = double(X);
    marges = X * modele.Beta + modele.Bias;
    if modele.Regression
        etiquettes = marges;
        scores = marges;
        return;
    end
    if strcmp(modele.Learner, 'logistic')
        probabilite = 1 ./ (1 + exp(-marges));
        scores = [1 - probabilite, probabilite];
    else
        scores = [-marges, marges];
    end
    choix = ones(size(marges));
    choix(marges > 0) = 2;
    etiquettes = modele.Classes(choix);
end
