function [etiquettes, scores] = predictEcoc(modele, X)
%PREDICTECOC Prédiction d'un modèle à codes correcteurs.
%   Employer PREDICT ; cette fonction est le rouage qu'il appelle.
    X = double(X);
    n = size(X, 1);
    k = numel(modele.Classes);
    votes = zeros(n, k);
    for m = 1:numel(modele.Modeles)
        sortie = predict(modele.Modeles{m}, X);
        sortie = double(sortie(:));
        a = modele.Paires(m, 1);
        b = modele.Paires(m, 2);
        if b == 0
            votes(:, a) = votes(:, a) + (sortie > 0);
        else
            votes(:, a) = votes(:, a) + (sortie < 0);
            votes(:, b) = votes(:, b) + (sortie > 0);
        end
    end
    scores = votes;
    [~, choix] = max(votes, [], 2);
    etiquettes = modele.Classes(choix);
end
