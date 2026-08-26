function r = imbothat(image, element)
%IMBOTHAT Chapeau bas de forme : la fermeture moins l'image.
%   Fait ressortir les détails sombres.
    r = double(imclose(image, element)) - double(image);
end
