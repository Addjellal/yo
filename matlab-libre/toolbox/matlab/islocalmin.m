function [marque, proeminence] = islocalmin(a, varargin)
%ISLOCALMIN Repère les minima locaux d'un vecteur.
%   M = ISLOCALMIN(A) rend un tableau logique vrai aux minima locaux :
%   les points strictement plus petits que leurs deux voisins.
%
%   Les options sont celles d'ISLOCALMAX — 'MinProminence',
%   'MinSeparation' et 'MaxNumExtrema' — appliquées au signal retourné :
%   un minimum de A est un maximum de -A, et il n'y a pas d'autre
%   différence entre les deux fonctions.
%
%   [M,P] = ISLOCALMIN(...) rend en outre la proéminence, comptée vers le
%   bas.
%
%   Exemple :
%      islocalmin([3 1 2 0 4])             % [0 1 0 1 0]
%      islocalmin([3 1 2 0 4], 'MinProminence', 2)
%
%   Voir aussi ISLOCALMAX, FINDPEAKS, ISCHANGE, MIN.
    [marque, proeminence] = matlibre_extrema_locaux(a, varargin, false);
end
