function y = randintrlv(donnees, germe)
%RANDINTRLV Entrelacement par une permutation pseudo-aléatoire.
%   Y = RANDINTRLV(DONNEES,GERME) entrelace avec la permutation que
%   produit le générateur initialisé par GERME. Le même germe redonne la
%   même permutation : c'est ce qui permet au récepteur de désentrelacer
%   sans transmettre la table.
%
%   Exemple :
%      y = randintrlv(1:8, 42);
%      isequal(randdeintrlv(y, 42), 1:8)   % vrai
%
%   Voir aussi RANDDEINTRLV, INTRLV.
    permutation = permutationAleatoire(tailleEntrelacement(donnees), germe);
    y = intrlv(donnees, permutation);
end
