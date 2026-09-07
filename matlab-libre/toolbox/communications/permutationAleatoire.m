function permutation = permutationAleatoire(n, germe)
%PERMUTATIONALEATOIRE Permutation reproductible de 1 à N.
%   L'état du générateur est sauvegardé puis restauré : appeler un
%   entrelaceur ne doit pas déranger le reste du programme.
%
%   Exemple :
%      p = permutationAleatoire(20, 3);
%            isequal(p, permutationAleatoire(20, 3))     % 1 : meme germe
%
%   Voir aussi INTRLV, VERIFIERPERMUTATION.
    etat = rng;
    rng(germe);
    permutation = randperm(n);
    rng(etat);
end
