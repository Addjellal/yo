function y = deintrlv(donnees, permutation)
%DEINTRLV Désentrelacement, réciproque de INTRLV.
%   Y = DEINTRLV(DONNEES,PERMUTATION) remet chaque élément à sa place :
%   Y(PERMUTATION(k)) = DONNEES(k).
%
%   Exemple :
%      deintrlv(intrlv([10 20 30 40], [3 1 4 2]), [3 1 4 2])   % inchangé
%
%   Voir aussi INTRLV, RANDDEINTRLV, MATDEINTRLV.
    permutation = round(double(permutation(:)))';
    verifierPermutation(permutation);
    inverse = zeros(1, numel(permutation));
    inverse(permutation) = 1:numel(permutation);
    y = intrlv(donnees, inverse);
end
