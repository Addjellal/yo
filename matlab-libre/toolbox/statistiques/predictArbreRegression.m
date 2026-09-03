function y = predictArbreRegression(arbre, X)
%PREDICTARBREREGRESSION Prédiction d'un arbre construit par FITRTREE.
%   Employer PREDICT ; cette fonction est le rouage qu'il appelle.
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
