function r = imtophat(image, element)
%IMTOPHAT Chapeau haut de forme : l'image moins son ouverture.
%   Fait ressortir les détails clairs plus petits que l'élément
%   structurant.
    r = double(image) - double(imopen(image, element));
end
