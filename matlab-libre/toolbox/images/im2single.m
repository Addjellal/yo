function y = im2single(x)
%IM2SINGLE Convertit une image en simple précision, de 0 à 1.
%   Y = IM2SINGLE(X) ramène une image entière à l'intervalle [0,1] en
%   simple précision. Une image déjà flottante est convertie sans être
%   remise à l'échelle : elle y est déjà.
%
%   La simple précision porte environ sept chiffres significatifs — bien
%   assez pour une image, dont la source n'en porte que deux ou trois —
%   et occupe la moitié de la mémoire d'un double. C'est pour cela qu'elle
%   sert au traitement d'images plutôt qu'au calcul numérique.
%
%   Exemple :
%      im2single(uint8(255)) == single(1)     % le blanc vaut un
%      class(im2single(uint8(0)))             % single
%
%   Voir aussi IM2DOUBLE, IM2UINT8, IM2UINT16.
    if isa(x, 'single')
        y = x;
    else
        y = single(im2double(x));
    end
end
