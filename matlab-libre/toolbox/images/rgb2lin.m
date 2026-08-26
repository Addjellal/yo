function u = rgb2lin(v, varargin)
%RGB2LIN Défait la correction gamma d'une image sRGB.
%   U = RGB2LIN(V) applique la fonction de transfert inverse de sRGB :
%   une droite près de zéro, une puissance 2,4 au-delà. Les valeurs
%   entrent et sortent entre 0 et 1.
%
%   Exemple :
%      rgb2lin(0.5)   % 0.2140
    v = im2double(v);
    seuil = 0.04045;
    u = zeros(size(v));
    bas = v <= seuil;
    u(bas) = v(bas) / 12.92;
    u(~bas) = ((v(~bas) + 0.055) / 1.055) .^ 2.4;
end
