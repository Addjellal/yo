function rgb = gray2rgb(g)
%GRAY2RGB Réplique une image en niveaux de gris sur trois canaux.
%   RGB = GRAY2RGB(G) recopie le plan de gris sur les trois canaux.
%
%   L'image obtenue est toujours grise : la conversion n'invente aucune
%   couleur, elle change seulement la représentation. Elle sert à
%   superposer un tracé en couleur sur un fond en gris, ce qu'un tableau à
%   deux dimensions ne permet pas.
%
%   Exemple :
%      rgb = gray2rgb(rand(8));
%      size(rgb)                       % 8 8 3
%      max(max(abs(rgb(:,:,1) - rgb(:,:,3))))    % 0 : toujours du gris
%
%   Voir aussi RGB2GRAY, IND2RGB, IM2DOUBLE.
    [h, l] = size(g);
    rgb = zeros(h, l, 3);
    rgb(:,:,1) = g;
    rgb(:,:,2) = g;
    rgb(:,:,3) = g;
end
