function r = imadd(a, b)
%IMADD Somme de deux images, avec saturation pour les entiers.
%   Z = IMADD(X,Y) additionne deux images de même taille, ou une image et
%   une constante.
%
%   Les opérations arithmétiques sur images saturent au lieu de déborder :
%   sur des entiers, 200 + 100 vaut 255 et non 44. C'est ce qui les
%   distingue de l'arithmétique ordinaire, et c'est presque toujours ce
%   qu'on veut d'une image.
%
%   Exemple :
%      imadd(uint8(200), uint8(100))   % 255, non 44
%
%   Voir aussi IMSUBTRACT, IMMULTIPLY, IMDIVIDE, IMABSDIFF.
    if isinteger(a)
        r = a + cast(b, class(a));
    elseif isinteger(b)
        r = cast(a, class(b)) + b;
    else
        r = double(a) + double(b);
    end
end
