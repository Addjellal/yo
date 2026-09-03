function BW = im2bw(I, carte, seuil)
%IM2BW Convertit une image en noir et blanc par seuillage.
%   BW = IM2BW(I,SEUIL) rend une image binaire : vrai là où I dépasse
%   SEUIL, qui s'exprime entre 0 et 1 quelle que soit la classe de I.
%   BW = IM2BW(I) emploie le seuil d'Otsu, que rend GRAYTHRESH.
%   BW = IM2BW(X,CARTE,SEUIL) convertit d'abord une image indexée.
%
%   Cette fonction est l'ancienne forme ; IMBINARIZE la remplace depuis
%   R2016a et offre le seuillage adaptatif.
%
%   Exemple :
%      BW = im2bw(mat2gray(magic(8)), 0.5);
%
%   Voir aussi IMBINARIZE, GRAYTHRESH, MULTITHRESH, IMQUANTIZE.
    if nargin >= 2 && (size(carte, 2) == 3 && size(carte, 1) > 1)
        I = ind2gray(I, carte);
        if nargin < 3
            seuil = graythresh(I);
        end
    else
        if nargin >= 2
            seuil = carte;
        else
            seuil = graythresh(im2double(I));
        end
    end
    I = im2double(I);
    BW = I > seuil;
end
