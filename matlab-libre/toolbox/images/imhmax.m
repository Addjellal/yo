function sortie = imhmax(image, h, connexite)
%IMHMAX Supprime les maxima de hauteur inférieure à H.
%   La reconstruction de l'image depuis elle-même abaissée de H rabote
%   les sommets peu marqués et laisse les autres.
%
%   Exemple :
%      imhmax([1 3 1], 5)   % [1 1 1] : le sommet ne fait que 2
    if nargin < 3 || isempty(connexite), connexite = 8; end
    image = double(image);
    sortie = imreconstruct(image - h, image, connexite);
end
