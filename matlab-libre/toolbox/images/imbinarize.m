function b = imbinarize(x, seuil)
%IMBINARIZE Seuillage d'une image en niveaux de gris.
%   BW = IMBINARIZE(X) seuille par la méthode d'Otsu, qui choisit le seuil
%   maximisant la variance entre les deux classes.
%   BW = IMBINARIZE(X,SEUIL) impose le seuil.
%
%   Otsu ne suppose rien de l'image sinon que son histogramme est
%   bimodal : il cherche la séparation qui rend les deux groupes les plus
%   distincts possible. Sur une image dont l'éclairage varie, il échoue —
%   le seuil global ne convient alors nulle part, et il faut seuiller
%   localement.
%
%   Exemple :
%      bw = imbinarize([0.1 0.2; 0.8 0.9]);
%      sum(bw(:))                      % 2 : les deux clairs
%
%   Voir aussi HISTEQ, IMHIST, BWAREA, IMADJUST.
    x = im2double(x);
    if nargin < 2 || isempty(seuil)
        seuil = graythresh(x);
    end
    b = x > seuil;
end
