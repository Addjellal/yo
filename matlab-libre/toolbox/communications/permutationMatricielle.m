function permutation = permutationMatricielle(lignes, colonnes)
%PERMUTATIONMATRICIELLE Ordre de lecture colonne par colonne d'une
%   matrice remplie ligne par ligne.
    lignes = round(double(lignes));
    colonnes = round(double(colonnes));
    indices = reshape(1:(lignes * colonnes), colonnes, lignes)';
    permutation = indices(:)';
end
