function g = rgb2gray(rgb)
%RGB2GRAY Luminance d'une image couleur.
%   G = RGB2GRAY(RGB) applique la pondération de la recommandation
%   ITU-R BT.601 : environ 0,299 R + 0,587 V + 0,114 B.
%
%   Les trois poids ne sont pas égaux parce que l'œil ne l'est pas : il
%   est bien plus sensible au vert qu'au bleu. Une moyenne arithmétique
%   des trois canaux donnerait une image grise, mais pas la bonne — les
%   verts y paraîtraient trop sombres et les bleus trop clairs.
%
%   Les coefficients sont donnés à leur pleine précision, celle de
%   l'inversion de la matrice de la recommandation : ils somment
%   exactement à un, si bien qu'un gris reste ce qu'il est. Les valeurs
%   arrondies à quatre décimales, elles, somment à 0,9999 et assombrissent
%   imperceptiblement toute l'image.
%
%   Une image déjà en niveaux de gris est rendue telle quelle.
%
%   Exemple :
%      gris = repmat(0.5, 2, 2, 3);
%      max(max(abs(rgb2gray(gris) - 0.5)))  % 0 : le gris est conserve
%
%   Voir aussi IM2DOUBLE, IMADJUST, IMHIST.
    if ndims(rgb) < 3
        g = rgb;
        return;
    end
    x = im2double(rgb);
    g = 0.298936021293776 * x(:,:,1) ...
      + 0.587043074451121 * x(:,:,2) ...
      + 0.114020904255103 * x(:,:,3);
end
