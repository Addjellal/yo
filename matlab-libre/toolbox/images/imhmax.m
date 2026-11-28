function sortie = imhmax(image, h, connexite)
%IMHMAX Supprime les maxima de hauteur inférieure à H.
%   La reconstruction de l'image depuis elle-même abaissée de H rabote
%   les sommets peu marqués et laisse les autres.
%
%   Un sommet plus haut que H perd H ; un sommet moins haut disparaît,
%   et l'image entière s'abaisse alors jusqu'à la hauteur de son fond
%   diminuée de H, comme dans MATLAB pour une image en double.
%
%   Exemple :
%      imhmax([1 3 1], 1)   % [1 2 1] : le sommet perd 1
%      imhmax([1 3 1], 5)   % [-2 -2 -2] : le sommet (2) est sous H
%
%   Voir aussi IMRECONSTRUCT, IMREGIONALMAX, WATERSHED.
    if nargin < 3 || isempty(connexite), connexite = 8; end
    image = double(image);
    sortie = imreconstruct(image - h, image, connexite);
end
