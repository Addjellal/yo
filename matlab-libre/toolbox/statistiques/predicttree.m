function y = predicttree(arbre, X)
%PREDICTTREE Prédiction d'un arbre construit par FITCTREE.
%   Y = PREDICTTREE(ARBRE,X) descend chaque ligne de X dans l'arbre
%   construit par FITCTREE et rend l'étiquette de la feuille atteinte.
%
%   À chaque noeud, une seule variable est comparée à un seuil : la
%   descente ne fait que des coupes parallèles aux axes. C'est ce qui rend
%   l'arbre lisible — le chemin d'une observation s'énonce en français —
%   et ce qui le rend malhabile sur une frontière oblique, qu'il approche
%   par un escalier.
%
%   La prédiction est constante par morceaux : un arbre ne peut extrapoler
%   au-delà de ce qu'il a vu, et rend pour une observation lointaine
%   l'étiquette de la région la plus proche. C'est un défaut ou une
%   sécurité, selon ce qu'on attend.
%
%   Exemple :
%      X = [randn(30, 2); randn(30, 2) + 3];
%      y = [ones(30, 1); 2 * ones(30, 1)];
%      t = fitctree(X, y);
%      mean(predicttree(t, X) == y)
%
%   Voir aussi FITCTREE, PREDICT, PREDICTKNN.
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
