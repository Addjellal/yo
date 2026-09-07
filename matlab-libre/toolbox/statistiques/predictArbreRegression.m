function y = predictArbreRegression(arbre, X)
%PREDICTARBREREGRESSION Prédiction d'un arbre construit par FITRTREE.
%   Employer PREDICT ; cette fonction est le rouage qu'il appelle.
%
%   Exemple :
%      rng(1);
%      X = [randn(60, 2); randn(60, 2) + 3];
%      z = X(:, 1) * 2 - X(:, 2);
%      m = fitrtree(X, z);
%      rms(predictArbreRegression(m, X) - z) < rms(z - mean(z))
%
%   Voir aussi FITRTREE, PREDICT, PREDICTTREE.
    X = double(X);
    y = zeros(size(X, 1), 1);
    for i = 1:size(X, 1)
        noeud = arbre;
        while ~noeud.feuille
            if X(i, noeud.variable) <= noeud.seuil
                noeud = noeud.gauche;
            else
                noeud = noeud.droite;
            end
        end
        y(i) = noeud.valeur;
    end
end
