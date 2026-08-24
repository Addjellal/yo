function y = randdeintrlv(donnees, germe)
%RANDDEINTRLV Désentrelacement pseudo-aléatoire, réciproque de RANDINTRLV.
%
%   Exemple :
%      isequal(randdeintrlv(randintrlv(1:8, 42), 42), 1:8)   % vrai
%
%   Voir aussi RANDINTRLV, DEINTRLV.
    permutation = permutationAleatoire(tailleEntrelacement(donnees), germe);
    y = deintrlv(donnees, permutation);
end
