function [B, d] = matlibre_equilibrer(A)
%MATLIBRE_EQUILIBRER Équilibrage diagonal d'une matrice.
%   [B,D] = MATLIBRE_EQUILIBRER(A) rend B = diag(1./D) * A * diag(D), où D
%   ne porte que des puissances de deux : la transformation est donc
%   exacte en virgule flottante. B a des lignes et des colonnes de normes
%   voisines, ce qui améliore beaucoup le conditionnement des calculs de
%   valeurs propres et de sous-espaces invariants.
%
%   C'est l'algorithme de Parlett et Reinsch, celui qu'emploie tout
%   solveur de valeurs propres avant de travailler. Il sert ici aux
%   matrices hamiltoniennes des équations de Riccati : un modèle dont les
%   pôles vont de 10^-5 à 20 est autrement hors d'atteinte.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB, où BALANCE fait le même
%   travail.
%
%   Voir aussi BALANCE, EIG, MATLIBRE_RICCATI.
    n = size(A, 1);
    B = A;
    d = ones(n, 1);
    if n < 2
        return
    end
    convergee = false;
    for tour = 1:50
        convergee = true;
        for i = 1:n
            % La somme des modules de la ligne et de la colonne, terme
            % diagonal exclu : c'est lui qui ne bouge pas.
            ligne = sum(abs(B(i, :))) - abs(B(i, i));
            colonne = sum(abs(B(:, i))) - abs(B(i, i));
            if ligne == 0 || colonne == 0
                continue
            end
            facteur = 1;
            somme = ligne + colonne;
            while colonne < ligne / 2
                colonne = colonne * 2;
                ligne = ligne / 2;
                facteur = facteur * 2;
            end
            while colonne >= ligne * 2
                colonne = colonne / 2;
                ligne = ligne * 2;
                facteur = facteur / 2;
            end
            % On n'applique que ce qui gagne vraiment : sinon l'algorithme
            % oscille sans fin.
            if (colonne + ligne) < 0.95 * somme
                convergee = false;
                d(i) = d(i) * facteur;
                B(i, :) = B(i, :) / facteur;
                B(:, i) = B(:, i) * facteur;
            end
        end
        if convergee
            break
        end
    end
end
