function y = matintrlv(donnees, lignes, colonnes)
%MATINTRLV Entrelacement matriciel.
%   Y = MATINTRLV(DONNEES,NLIGNES,NCOLONNES) remplit une matrice ligne par
%   ligne avec les données, puis la lit colonne par colonne. Une rafale de
%   NLIGNES erreurs consécutives se retrouve ainsi répartie sur NLIGNES
%   mots distincts.
%
%   Le nombre d'éléments doit valoir NLIGNES*NCOLONNES.
%
%   Exemple :
%      matintrlv(1:6, 2, 3)   % [1 4 2 5 3 6]
%
%   Voir aussi MATDEINTRLV, INTRLV.
    permutation = permutationMatricielle(lignes, colonnes);
    y = intrlv(donnees, permutation);
end
