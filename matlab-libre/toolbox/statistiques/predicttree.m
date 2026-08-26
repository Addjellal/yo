function y = predicttree(arbre, X)
%PREDICTTREE Prédiction d'un arbre construit par FITCTREE.
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
        y(i) = noeud.classe;
    end
end
