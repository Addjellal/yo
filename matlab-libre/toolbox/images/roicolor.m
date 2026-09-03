function BW = roicolor(A, bas, haut)
%ROICOLOR Sélectionne une région par son intensité.
%   BW = ROICOLOR(A,BAS,HAUT) rend le masque des points dont la valeur
%   est comprise entre BAS et HAUT.
%   BW = ROICOLOR(A,V) rend le masque des points dont la valeur figure
%   dans le vecteur V.
%
%   Exemple :
%      BW = roicolor(magic(5), 10, 20);
%
%   Voir aussi ROIFILT2, POLY2MASK, IMBINARIZE, IMQUANTIZE.
    A = double(A);
    if nargin < 3
        valeurs = double(bas(:));
        BW = false(size(A));
        for k = 1:numel(valeurs)
            BW = BW | (A == valeurs(k));
        end
        return;
    end
    BW = (A >= double(bas)) & (A <= double(haut));
end
