function permutation = permutationMatricielle(lignes, colonnes)
%PERMUTATIONMATRICIELLE Ordre de lecture colonne par colonne d'une
%   matrice remplie ligne par ligne.
%
%   Exemple :
%      p = permutationMatricielle(3, 4);
%            isequal(sort(p(:))', 1:12)                  % 1 : c'est une permutation
%
%   Voir aussi INTRLV, DEINTRLV.
    lignes = round(double(lignes));
    colonnes = round(double(colonnes));
    indices = reshape(1:(lignes * colonnes), colonnes, lignes)';
    permutation = indices(:)';
end
