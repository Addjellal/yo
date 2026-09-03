function [etiquettes, scores] = predictSvm(modele, X)
%PREDICTSVM Prédiction d'une machine à vecteurs de support.
%   Employer PREDICT ; cette fonction est le rouage qu'il appelle.
    X = double(X);
    X = (X - repmat(modele.Centre, size(X, 1), 1)) ./ ...
        repmat(modele.Echelle, size(X, 1), 1);
    if isempty(modele.SupportVectors) && ~isempty(modele.Beta)
        % Un modèle allégé n'a plus que son vecteur de poids : c'est tout
        % ce dont une frontière linéaire a besoin.
        marges = X * modele.Beta + modele.Bias;
    elseif isempty(modele.SupportVectors)
        marges = zeros(size(X, 1), 1) + modele.Bias;
    else
        K = noyauSvm(X, modele.SupportVectors, modele.Options);
        marges = K * (modele.Alpha .* modele.Cible) + modele.Bias;
    end
    if modele.Regression
        etiquettes = marges;
        scores = marges;
        return;
    end
    scores = [-marges, marges];
    choix = ones(size(marges));
    choix(marges > 0) = 2;
    etiquettes = modele.Classes(choix);
end
