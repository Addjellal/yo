function [points, tailleDamier] = generateCheckerboardPoints(tailleDamier, tailleCarre)
%GENERATECHECKERBOARDPOINTS Coins théoriques d'un damier d'étalonnage.
%   P = GENERATECHECKERBOARDPOINTS([M N],T) rend les coordonnées des coins
%   intérieurs d'un damier de M par N carrés dont le côté mesure T. Il y
%   en a (M-1)*(N-1), rangés colonne par colonne, la première à l'origine.
%
%   Ce sont les points de référence auxquels comparer ceux détectés dans
%   une photographie du damier, pour en déduire les paramètres de la
%   caméra.
%
%   Exemple :
%      p = generateCheckerboardPoints([3 4], 10);
%      size(p)   % [6 2] : deux lignes de trois coins
%
%   Voir aussi ESTIMATEGEOMETRICTRANSFORM.
    if nargin < 2 || isempty(tailleCarre), tailleCarre = 1; end
    tailleDamier = double(tailleDamier);
    lignes = tailleDamier(1) - 1;
    colonnes = tailleDamier(2) - 1;
    if lignes < 1 || colonnes < 1
        error('vision:generateCheckerboardPoints:BadSize', ...
              'Le damier doit compter au moins deux carrés dans chaque sens.');
    end
    [X, Y] = meshgrid((0:colonnes-1) * tailleCarre, (0:lignes-1) * tailleCarre);
    points = [X(:), Y(:)];
end
