function [positions, metriques] = detectMinEigenFeatures(I, varargin)
%DETECTMINEIGENFEATURES Coins de Shi et Tomasi (1994).
%   [P,M] = DETECTMINEIGENFEATURES(I) rend les coordonnées [x y] des coins,
%   affinées au sous-pixel, et leur métrique : la plus petite valeur
%   propre du tenseur de structure lissé
%
%      T = [ Sxx Sxy ; Sxy Syy ],
%
%   qui vaut ((Sxx+Syy) - sqrt((Sxx-Syy)^2 + 4 Sxy^2)) / 2. Un coin est un
%   point où les deux valeurs propres sont grandes : prendre la plus
%   petite est plus direct que la combinaison de Harris, et c'est ce
%   critère qui décide des points à suivre dans un flot optique.
%   MATLAB rend un objet cornerPoints ; MatLibre rend ses champs Location
%   et Metric comme deux tableaux.
%
%   Options, comme MATLAB : 'MinQuality' (0.01), 'FilterSize' (5) et
%   'ROI' ([x y largeur hauteur]).
%
%   Exemple :
%      I = zeros(20); I(6:15, 6:15) = 1;
%      p = detectMinEigenFeatures(I);   % les quatre coins du carré
%
%   Voir aussi DETECTHARRISFEATURES, DETECTFASTFEATURES, SELECTSTRONGEST.
    [positions, metriques] = matlibre_coins(I, varargin, 'mineigen', 'detectMinEigenFeatures');
end
