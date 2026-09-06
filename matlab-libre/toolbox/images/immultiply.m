function r = immultiply(a, b)
%IMMULTIPLY Produit terme à terme de deux images.
%   Z = IMMULTIPLY(X,Y) multiplie terme à terme, ou par une constante.
%   C'est ainsi qu'on applique un masque ou qu'on module une luminosité.
%
%   Les opérations arithmétiques sur images saturent au lieu de déborder :
%   sur des entiers, 200 + 100 vaut 255 et non 44. C'est ce qui les
%   distingue de l'arithmétique ordinaire, et c'est presque toujours ce
%   qu'on veut d'une image.
%
%   Exemple :
%      immultiply(uint8(200), 2)       % 255 : sature
%
%   Voir aussi IMDIVIDE, IMADD, IMSUBTRACT.
    if isinteger(a)
        r = cast(double(a) .* double(b), class(a));
    elseif isinteger(b)
        r = cast(double(a) .* double(b), class(b));
    else
        r = double(a) .* double(b);
    end
end
