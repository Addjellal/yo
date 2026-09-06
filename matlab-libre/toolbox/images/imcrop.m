function y = imcrop(x, rectangle)
%IMCROP Découpe un rectangle dans une image.
%   Y = IMCROP(X,[XMIN YMIN LARGEUR HAUTEUR]) rend la partie de l'image
%   comprise dans le rectangle. XMIN et YMIN sont la colonne et la ligne
%   du coin supérieur gauche.
%
%   La taille rendue est HAUTEUR+1 sur LARGEUR+1, non HAUTEUR sur
%   LARGEUR : le rectangle décrit une étendue spatiale, du bord gauche du
%   premier pixel au bord droit du dernier, et non un compte de pixels.
%   C'est la convention de MATLAB, et elle surprend toujours.
%
%   Un rectangle qui déborde est ramené dans l'image : la fonction ne
%   complète pas, elle tronque.
%
%   Exemple :
%      image = reshape(1:100, 10, 10);
%      size(imcrop(image, [3 2 3 4]))       % [5 4] : hauteur+1, largeur+1
%      imcrop(image, [3 2 3 4])(1, 1)       % image(2, 3)
%
%   Voir aussi IMRESIZE, IMROTATE, IMADJUST.
    j0 = max(1, round(rectangle(1)));
    i0 = max(1, round(rectangle(2)));
    j1 = min(size(x, 2), j0 + round(rectangle(3)));
    i1 = min(size(x, 1), i0 + round(rectangle(4)));
    y = x(i0:i1, j0:j1, :);
end
