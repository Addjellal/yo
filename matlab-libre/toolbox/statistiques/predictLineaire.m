function [etiquettes, scores] = predictLineaire(modele, X)
%PREDICTLINEAIRE Prédiction d'un modèle linéaire de grande dimension.
%   Employer PREDICT ; cette fonction est le rouage qu'il appelle.
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
