function [positions, metriques] = detectHarrisFeatures(I, varargin)
%DETECTHARRISFEATURES Coins par le détecteur de Harris et Stephens (1988).
%   [P,M] = DETECTHARRISFEATURES(I) rend les positions [x y] des coins, une
%   ligne par coin, affinées au sous-pixel, et leur métrique
%      M = det(T) - 0.04 trace(T)^2,
%   T étant le tenseur de structure lissé par une gaussienne. MATLAB rend
%   un objet cornerPoints ; MatLibre rend ses deux champs Location et
%   Metric comme deux tableaux, que SELECTSTRONGEST sait trier.
%
%   Options, comme MATLAB : 'MinQuality' (0.01, la fraction du maximum de
%   la métrique sous laquelle un coin est écarté), 'FilterSize' (5, la
%   taille de la gaussienne, d'écart type FilterSize/3) et 'ROI'
%   ([x y largeur hauteur], la zone examinée).
%
%   Un coin est un maximum local de la métrique ; sur un plateau — un coin
%   de damier tombe entre quatre pixels de même métrique —, un seul pixel
%   est retenu, et la parabole qui passe par ses voisins place le coin
%   entre eux : à x = 10.5 pour une case de dix pixels.
%
%   Exemple :
%      [p, m] = detectHarrisFeatures(checkerboard(10));
%      size(p, 1)                  % 49 : les intersections intérieures
%
%   Voir aussi DETECTMINEIGENFEATURES, DETECTFASTFEATURES, SELECTSTRONGEST.
    [positions, metriques] = matlibre_coins(I, varargin, 'harris', 'detectHarrisFeatures');
end
