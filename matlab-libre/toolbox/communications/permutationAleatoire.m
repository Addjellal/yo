function permutation = permutationAleatoire(n, germe)
%PERMUTATIONALEATOIRE Permutation reproductible de 1 à N.
%   L'état du générateur est sauvegardé puis restauré : appeler un
%   entrelaceur ne doit pas déranger le reste du programme.
    etat = rng;
    rng(germe);
    permutation = randperm(n);
    rng(etat);
end
