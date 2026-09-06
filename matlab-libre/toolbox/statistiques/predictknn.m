function etiquettes = predictknn(modele, Xnouveau)
%PREDICTKNN Prédiction d'un classifieur k plus proches voisins.
%   ETIQUETTES = PREDICTKNN(MODELE,XNOUVEAU) classe chaque ligne de
%   XNOUVEAU par vote majoritaire de ses K plus proches voisins dans les
%   données mémorisées par FITCKNN.
%
%   Il n'y a pas eu d'apprentissage : tout le coût est reporté sur la
%   prédiction, qui cherche les voisins dans l'ensemble d'entraînement à
%   chaque appel. C'est ce qui rend la méthode immédiate à mettre en
%   oeuvre et coûteuse à l'usage.
%
%   La distance est euclidienne, donc dominée par la variable de plus
%   grande amplitude : mesurer une longueur en millimètres plutôt qu'en
%   mètres change les voisins et donc la réponse. Normaliser les colonnes
%   avant d'appeler FITCKNN n'est pas un raffinement mais une nécessité.
%
%   Un K pair peut donner une égalité de voix, tranchée ici par MODE, qui
%   retient la plus petite étiquette : un K impair l'évite en deux classes.
%
%   Exemple :
%      X = [randn(30, 2); randn(30, 2) + 3];
%      y = [ones(30, 1); 2 * ones(30, 1)];
%      m = fitcknn(X, y, 'NumNeighbors', 3);
%      mean(predictknn(m, X) == y)
%
%   Voir aussi FITCKNN, KNNSEARCH, PREDICT, PREDICTTREE.
    [indices, ~] = knnsearch(modele.X, Xnouveau, 'K', modele.K);
    m = size(Xnouveau, 1);
    etiquettes = zeros(m, 1);
    for i = 1:m
        voisins = modele.Y(indices(i, :));
        etiquettes(i) = mode(voisins);
    end
end
