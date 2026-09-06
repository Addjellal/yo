function [nombre, taux] = symerr(a, b)
%SYMERR Nombre et taux d'erreurs symbole.
%   NOMBRE = SYMERR(A,B) compte les positions où A et B diffèrent.
%   [NOMBRE,TAUX] = SYMERR(A,B) rend en plus ce nombre divisé par le
%   nombre de symboles comparés.
%
%   La comparaison est faite symbole par symbole, sans regarder de quelle
%   valeur ils diffèrent : c'est ce qu'il faut pour mesurer une chaîne de
%   transmission, où une erreur est une erreur, quelle que soit sa
%   grandeur.
%
%   Le taux symbole est toujours supérieur ou égal au taux binaire de
%   BITERR, et vaut au plus BITS fois celui-ci. Un codage de Gray, qui
%   fait différer d'un seul bit deux symboles voisins de la constellation,
%   rapproche le taux binaire de TAUX/BITS ; sans lui, une erreur entre
%   voisins peut faire basculer tous les bits à la fois.
%
%   Exemple :
%      [n, t] = symerr([0 1 2 3], [0 1 3 3]);
%
%   Voir aussi BITERR, PSKDEMOD, QAMDEMOD.
    nombre = sum(a(:) ~= b(:));
    taux = nombre / numel(a);
end
