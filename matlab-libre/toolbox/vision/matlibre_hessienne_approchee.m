function [reponse, trace] = matlibre_hessienne_approchee(integrale, marge, taille, cote)
%MATLIBRE_HESSIENNE_APPROCHEE Déterminant de la Hessienne, par boîtes.
%   [R,T] = MATLIBRE_HESSIENNE_APPROCHEE(INTEGRALE,MARGE,TAILLE,COTE) rend
%   le déterminant de la matrice hessienne approchée par des filtres à
%   boîte de côté COTE, et la trace, dont le signe distingue une tache
%   sombre d'une tache claire.
%
%   Les dérivées secondes d'une gaussienne sont remplacées par des
%   rectangles de poids constants, ce qui les rend calculables en temps
%   fixe depuis l'image intégrale, quelle que soit l'échelle. Le
%   déterminant est corrigé du facteur habituel, qui compense l'écart
%   entre la boîte et la gaussienne qu'elle imite, et normalisé par
%   l'aire du filtre pour que deux échelles soient comparables.
%
%   Exemple :
%      P = padarray(fspecial('gaussian', 41, 4) * 1e4, [30 30], 'replicate');
%      R = matlibre_hessienne_approchee(integralImage(P), 30, [41 41], 9);
%      R(21, 21) > 0     % la tache est détectée
%
%   Voir aussi DETECTSURFFEATURES, MATLIBRE_SOMME_BOITE.
    l = round(cote / 3);
    demi = floor(cote / 2);
    lobe = l - 1;
    % Dxx : trois boîtes côte à côte, de poids +1, -2, +1.
    dxx = matlibre_somme_boite(integrale, marge, taille, ...
                               [-lobe, lobe, -demi, -demi + l - 1]) ...
        - 2 * matlibre_somme_boite(integrale, marge, taille, ...
                               [-lobe, lobe, -floor(l / 2), -floor(l / 2) + l - 1]) ...
        + matlibre_somme_boite(integrale, marge, taille, ...
                               [-lobe, lobe, demi - l + 1, demi]);
    dyy = matlibre_somme_boite(integrale, marge, taille, ...
                               [-demi, -demi + l - 1, -lobe, lobe]) ...
        - 2 * matlibre_somme_boite(integrale, marge, taille, ...
                               [-floor(l / 2), -floor(l / 2) + l - 1, -lobe, lobe]) ...
        + matlibre_somme_boite(integrale, marge, taille, ...
                               [demi - l + 1, demi, -lobe, lobe]);
    % Dxy : quatre boîtes carrées, en diagonale opposée.
    dxy = matlibre_somme_boite(integrale, marge, taille, [-l, -1, -l, -1]) ...
        - matlibre_somme_boite(integrale, marge, taille, [-l, -1, 1, l]) ...
        - matlibre_somme_boite(integrale, marge, taille, [1, l, -l, -1]) ...
        + matlibre_somme_boite(integrale, marge, taille, [1, l, 1, l]);
    aire = cote ^ 2;
    dxx = dxx / aire;
    dyy = dyy / aire;
    dxy = dxy / aire;
    reponse = dxx .* dyy - (0.912 * dxy) .^ 2;
    trace = dxx + dyy;
end
