function y = imgaussfilt(x, sigma)
%IMGAUSSFILT Lissage gaussien d'une image.
%   Y = IMGAUSSFILT(X,SIGMA) convolue par une gaussienne d'écart type
%   SIGMA, 0,5 par défaut.
%
%   La gaussienne est le seul noyau séparable et isotrope à la fois : on
%   peut donc filtrer les lignes puis les colonnes, ce qui coûte 2N au
%   lieu de N carré. C'est aussi le seul qui ne crée aucun extremum
%   nouveau — d'où son emploi comme base des espaces d'échelle.
%
%   Le support effectif vaut environ trois écarts types de part et
%   d'autre : au-delà, la gaussienne est négligeable.
%
%   Exemple :
%      lisse = imgaussfilt(rand(64), 2);
%      std(lisse(:)) < std(rand(64))   % true : le lissage reduit l'ecart
%
%   Voir aussi IMFILTER, FSPECIAL, MEDFILT2.
    if nargin < 2
        sigma = 0.5;
    end
    n = 2 * ceil(2 * sigma) + 1;
    h = fspecial('gaussian', n, sigma);
    y = imfilter(x, h);
end
