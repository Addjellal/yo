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
              'Le nœud %d n''est pas dans l''arbre.', indice);
    end
    % On remonte le nœud seul, en mettant à zéro le frère à chaque étage.
    if arbre.dimension == 1
        courant = donnees;
        while indice > 0
            vide = zeros(size(courant));
            if mod(indice, 2) == 1
                courant = idwt(courant, vide, arbre.nom);
            else
                courant = idwt(vide, courant, arbre.nom);
            end
            indice = floor((indice - 1) / 2);
        end
        x = wkeep(courant, arbre.longueur);
        if ~arbre.ligne
            x = x(:);
        end
    else
        courant = donnees;
        while indice > 0
            vide = zeros(size(courant));
            rang = mod(indice - 1, 4);
            morceaux = {vide, vide, vide, vide};
            morceaux{rang + 1} = courant;
            courant = idwt2(morceaux{1}, morceaux{2}, morceaux{3}, morceaux{4}, arbre.nom);
            indice = floor((indice - 1) / 4);
        end
        x = wkeep(courant, arbre.taille);
    end
end
