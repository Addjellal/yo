function r = imdivide(a, b)
%IMDIVIDE Quotient terme à terme de deux images.
%   Z = IMDIVIDE(X,Y) divise terme à terme. La division par zéro rend la
%   valeur maximale du type plutôt qu'un infini, qui n'a pas de sens dans
%   une image entière.
%
%   Les opérations arithmétiques sur images saturent au lieu de déborder :
%   sur des entiers, 200 + 100 vaut 255 et non 44. C'est ce qui les
%   distingue de l'arithmétique ordinaire, et c'est presque toujours ce
%   qu'on veut d'une image.
%
%   Exemple :
%      imdivide(uint8(100), 2)         % 50
%
%   Voir aussi IMMULTIPLY, IMADD, IMSUBTRACT.
    if isinteger(a)
        r = cast(double(a) ./ double(b), class(a));
    else
        r = double(a) ./ double(b);
    end
end
