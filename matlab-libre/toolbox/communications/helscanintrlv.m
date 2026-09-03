function y = helscanintrlv(donnees, lignes, colonnes, pas)
%HELSCANINTRLV Entrelacement par balayage hélicoïdal.
%   Y = HELSCANINTRLV(X,NLIGNES,NCOLONNES,PAS) range X dans une matrice
%   ligne par ligne, puis la lit en diagonale : la lecture part du coin
%   supérieur gauche et descend d'une ligne à chaque colonne, en avançant
%   de PAS colonnes à chaque ligne.
%
%   Le nombre d'éléments doit valoir NLIGNES*NCOLONNES.
%
%   Le balayage hélicoïdal disperse mieux qu'un entrelacement matriciel
%   simple : deux symboles voisins à l'entrée se retrouvent séparés à la
%   fois en ligne et en colonne.
%
%   Exemple :
%      y = helscanintrlv(1:12, 3, 4, 1);
%      x = helscandeintrlv(y, 3, 4, 1);
%      isequal(x, 1:12)               % vrai
%
%   Voir aussi HELSCANDEINTRLV, MATINTRLV, MUXINTRLV, INTRLV.
    permutation = matlibre_helice(lignes, colonnes, pas);
    y = intrlv(donnees, permutation);
end
