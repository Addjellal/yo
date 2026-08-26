function bw = imregionalmax(image, connexite)
%IMREGIONALMAX Maxima régionaux d'une image.
%   Un maximum régional est un plateau connexe dont tous les voisins sont
%   strictement plus bas. On le trouve en reconstruisant l'image depuis
%   elle-même diminuée d'un cran : ce qui reste au-dessus est un maximum.
%
%   Le « cran » est pris sur les rangs des valeurs, pas sur les valeurs
%   elles-mêmes : les maxima régionaux ne changent pas si l'on applique
%   une fonction strictement croissante, et travailler sur les rangs rend
%   le calcul exact même en présence d'infinis.
%
%   Exemple :
%      imregionalmax([1 2 1; 2 3 2; 1 2 1])   % le centre seulement
    if nargin < 2 || isempty(connexite), connexite = 8; end
    image = double(image);
    [~, ~, rangs] = unique(image(:));
    niveaux = reshape(rangs, size(image));
    reconstruit = imreconstruct(niveaux - 1, niveaux, connexite);
    bw = niveaux > reconstruit;
end
