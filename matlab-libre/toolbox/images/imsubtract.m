function r = imsubtract(a, b)
%IMSUBTRACT Différence de deux images, avec saturation pour les entiers.
%   Z = IMSUBTRACT(X,Y) soustrait terme à terme.
%
%   Les opérations arithmétiques sur images saturent au lieu de déborder :
%   sur des entiers, 200 + 100 vaut 255 et non 44. C'est ce qui les
%   distingue de l'arithmétique ordinaire, et c'est presque toujours ce
%   qu'on veut d'une image.
%
%   Exemple :
%      imsubtract(uint8(50), uint8(100))   % 0, non 206
%
%   Voir aussi IMADD, IMABSDIFF, IMMULTIPLY.
    if isinteger(a)
        r = a - cast(b, class(a));
    elseif isinteger(b)
        r = cast(a, class(b)) - b;
    else
        r = double(a) - double(b);
    end
end
