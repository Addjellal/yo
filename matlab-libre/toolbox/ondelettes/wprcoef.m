function x = wprcoef(arbre, noeud)
%WPRCOEF Reconstruction de la seule composante d'un nœud.
%   X = WPRCOEF(T,N) reconstruit le signal en ne gardant que le nœud N :
%   tous les autres sont mis à zéro. On voit ainsi ce que cette bande de
%   fréquence apporte au signal.
%
%   La somme des WPRCOEF de toutes les feuilles redonne le signal : c'est
%   la décomposition que l'arbre représente.
%
%   Exemple :
%      t = wpdec(1:64, 2, 'db2');
%      somme = zeros(1, 64);
%      for n = leaves(t)', somme = somme + wprcoef(t, n); end
%      max(abs(somme - (1:64)))       % nul
%
%   Voir aussi WPREC, WPCOEF, WPDEC, LEAVES.
    indice = indiceDeNoeud(arbre, noeud);
    donnees = lireNoeud(arbre, indice);
    if isempty(donnees)
        error('wavelet:wprcoef:Absent', ...
              'Node %d is not in the tree.', indice);
    end
    % On remonte le nœud seul, en mettant à zéro le frère à chaque étage.
    if arbre.dimension == 1
        courant = donnees;
        while indice > 0
            parent = floor((indice - 1) / 2);
            taille = matlibre_taille_noeud(arbre, parent);
            if mod(indice, 2) == 1
                courant = idwt(courant, [], arbre.nom, taille);
            else
                courant = idwt([], courant, arbre.nom, taille);
            end
            indice = parent;
        end
        x = wkeep(courant, arbre.longueur);
        if ~arbre.ligne
            x = x(:);
        end
    else
        courant = donnees;
        while indice > 0
            parent = floor((indice - 1) / 4);
            rang = mod(indice - 1, 4);
            morceaux = {[], [], [], []};
            morceaux{rang + 1} = courant;
            courant = idwt2(morceaux{1}, morceaux{2}, morceaux{3}, morceaux{4}, arbre.nom, ...
                            matlibre_taille_noeud(arbre, parent));
            indice = parent;
        end
        x = wkeep(courant, arbre.taille);
    end
end
