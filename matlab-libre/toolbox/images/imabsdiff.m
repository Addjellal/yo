function r = imabsdiff(a, b)
%IMABSDIFF Différence absolue de deux images, sans dépassement.
%   Z = IMABSDIFF(X,Y) rend la valeur absolue de la différence : elle ne
%   sature jamais, contrairement à IMSUBTRACT, puisque le résultat tient
%   toujours dans le type. C'est ce qui en fait l'outil de la détection de
%   mouvement entre deux images.
%
%   Les opérations arithmétiques sur images saturent au lieu de déborder :
%   sur des entiers, 200 + 100 vaut 255 et non 44. C'est ce qui les
%   distingue de l'arithmétique ordinaire, et c'est presque toujours ce
%   qu'on veut d'une image.
%
%   Exemple :
%      imabsdiff(uint8(50), uint8(100))    % 50, dans les deux sens
%
%   Voir aussi IMSUBTRACT, IMMSE, IMADD.
    if isinteger(a) || isinteger(b)
        r = cast(abs(double(a) - double(b)), class(a));
    else
        r = abs(double(a) - double(b));
    end
end
