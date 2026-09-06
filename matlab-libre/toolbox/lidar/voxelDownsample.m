function reduits = voxelDownsample(points, taille)
%VOXELDOWNSAMPLE Un point par cellule de la grille, au barycentre.
%   R = VOXELDOWNSAMPLE(POINTS,TAILLE) découpe l'espace en cellules
%   cubiques de côté TAILLE et ne garde qu'un point par cellule occupée,
%   placé au barycentre de ceux qu'elle contenait.
%
%   Un télémètre produit bien plus de points qu'il n'en faut, et surtout
%   les produit inégalement : très dense près du capteur, clairsemé loin.
%   Le sous-échantillonnage par voxels égalise cette densité, ce qui
%   change tout pour les méthodes qui la supposent uniforme — ICP en
%   premier lieu, qui sans cela tire vers les zones denses.
%
%   Prendre le barycentre plutôt qu'un point au hasard réduit aussi le
%   bruit de mesure, d'un facteur racine du nombre de points de la
%   cellule.
%
%   TAILLE est le seul réglage : plus grosse, moins de points, et moins de
%   détail. Deux points d'une même cellule ne peuvent pas survivre tous
%   les deux — c'est la garantie de la méthode.
%
%   Exemple :
%      nuage = randn(1000, 2) * 0.3;
%      size(voxelDownsample(nuage, 0.25), 1)   % bien moins de 1000
%
%   Voir aussi POINTCLOUDFROMRANGES, FITPLANERANSAC.
    cles = floor(points / taille);
    vus = [];
    reduits = [];
    for k = 1:size(points, 1)
        c = cles(k, :);
        trouve = false;
        for j = 1:size(vus, 1)
            if all(vus(j, :) == c)
                trouve = true;
                break;
            end
        end
        if ~trouve
            vus(end+1, :) = c;
            membres = true(size(points, 1), 1);
            for d = 1:size(points, 2)
                membres = membres & (cles(:, d) == c(d));
            end
            reduits(end+1, :) = mean(points(membres, :), 1);
        end
    end
end
