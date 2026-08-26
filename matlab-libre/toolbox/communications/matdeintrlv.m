function y = matdeintrlv(donnees, lignes, colonnes)
%MATDEINTRLV Désentrelacement matriciel, réciproque de MATINTRLV.
%
%   Exemple :
%      isequal(matdeintrlv(matintrlv(1:6, 2, 3), 2, 3), 1:6)   % vrai
%
%   Voir aussi MATINTRLV, DEINTRLV.
    permutation = permutationMatricielle(lignes, colonnes);
    y = deintrlv(donnees, permutation);
end
