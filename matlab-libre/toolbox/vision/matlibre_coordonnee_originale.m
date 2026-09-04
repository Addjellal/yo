function q = matlibre_coordonnee_originale(p, echelle)
%MATLIBRE_COORDONNEE_ORIGINALE Ramène un point d'un niveau réduit.
%   Q = MATLIBRE_COORDONNEE_ORIGINALE(P,ECHELLE) rend la position, dans
%   l'image de départ, du point P repéré dans une image réduite ECHELLE
%   fois. Le décalage d'un demi-pixel est celui de la convention des
%   centres de pixel : le pixel un couvre l'intervalle de 0,5 à 1,5.
%
%   Exemple :
%      matlibre_coordonnee_originale([1 1], 2)     % 1.5 1.5
%
%   Voir aussi DETECTORBFEATURES, DETECTBRISKFEATURES, IMRESIZE.
    q = (double(p) - 0.5) * echelle + 0.5;
end
