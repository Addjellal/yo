function [marque, proeminence] = islocalmax(a, varargin)
%ISLOCALMAX Repère les maxima locaux d'un vecteur.
%   M = ISLOCALMAX(A) rend un tableau logique de la taille de A, vrai aux
%   maxima locaux : les points strictement plus grands que leurs deux
%   voisins. Les extrémités ne sont jamais des maxima locaux, faute d'un
%   voisin de chaque côté.
%
%   M = ISLOCALMAX(A,'MinProminence',P) n'en garde que ceux dont la
%   proéminence atteint P. La proéminence d'un sommet est sa hauteur
%   au-dessus du col le plus haut qui le sépare d'un sommet plus élevé :
%   c'est ce qui distingue un vrai pic d'une ondulation posée sur un
%   flanc, et c'est la seule mesure qui ne dépende pas de l'échelle
%   verticale choisie.
%
%   M = ISLOCALMAX(A,'MinSeparation',S) impose une distance minimale entre
%   deux maxima retenus ; le plus proéminent l'emporte.
%   M = ISLOCALMAX(A,'MaxNumExtrema',N) n'en garde que les N plus
%   proéminents.
%
%   [M,P] = ISLOCALMAX(...) rend en outre la proéminence de chaque point,
%   nulle là où il n'y a pas de maximum local.
%
%   Un plateau ne compte que pour un maximum, placé sur son premier point :
%   sans cette règle, un signal quantifié en produirait autant que le
%   plateau a d'échantillons.
%
%   Exemple :
%      islocalmax([1 3 2 5 4])             % [0 1 0 1 0]
%      islocalmax([1 3 2 5 4], 'MinProminence', 2)
%      [m, p] = islocalmax([0 1 0 5 0]);
%      p(4)                                % 5 : le grand pic dominate
%
%   Voir aussi ISLOCALMIN, FINDPEAKS, ISCHANGE, MAX.
    [marque, proeminence] = matlibre_extrema_locaux(a, varargin, true);
end
