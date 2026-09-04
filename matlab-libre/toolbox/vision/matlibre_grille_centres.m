function [x, y] = matlibre_grille_centres(hauteur, largeur, pas)
%MATLIBRE_GRILLE_CENTRES Centres de départ répartis sur l'image.
%   [X,Y] = MATLIBRE_GRILLE_CENTRES(H,L,PAS) place des points aux nœuds
%   d'une grille de maille PAS, sans en poser sur le bord : chacun sera le
%   germe d'une région.
%
%   Exemple :
%      [x, y] = matlibre_grille_centres(60, 60, 15);
%      numel(x)    % 16
%
%   Voir aussi SUPERPIXELS.
    nx = max(1, round(largeur / pas));
    ny = max(1, round(hauteur / pas));
    if nx == 1
        xs = round(largeur / 2);
    else
        xs = round(linspace(pas / 2, largeur - pas / 2, nx));
    end
    if ny == 1
        ys = round(hauteur / 2);
    else
        ys = round(linspace(pas / 2, hauteur - pas / 2, ny));
    end
    xs = min(max(xs, 1), largeur);
    ys = min(max(ys, 1), hauteur);
    [X, Y] = meshgrid(xs, ys);
    x = X(:);
    y = Y(:);
end
