function sortie = imclearborder(image, connexite)
%IMCLEARBORDER Supprime les objets qui touchent le bord de l'image.
%   La reconstruction part du bord : tout ce qu'elle atteint est retiré.
%
%   Exemple :
%      bw = false(5); bw(1,1) = true; bw(3,3) = true;
%      imclearborder(bw)   % il ne reste que le point du centre
    if nargin < 2 || isempty(connexite), connexite = 8; end
    estLogique = islogical(image);
    image = double(image);
    marqueur = zeros(size(image));
    marqueur(1, :) = image(1, :);
    marqueur(end, :) = image(end, :);
    marqueur(:, 1) = image(:, 1);
    marqueur(:, end) = image(:, end);
    sortie = image - imreconstruct(marqueur, image, connexite);
    if estLogique
        sortie = logical(sortie);
    end
end
