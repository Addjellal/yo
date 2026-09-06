function rgb = ind2rgb(indices, carte)
%IND2RGB Image indexée vers image en couleurs.
%   RGB = IND2RGB(X,CARTE) remplace chaque indice par la couleur qu'il
%   désigne dans la palette.
%
%   Une image indexée sépare la géométrie de la couleur : la même image
%   change entièrement d'aspect quand on change de palette, sans qu'aucun
%   pixel ne bouge. C'est ce qui rend les fausses couleurs si commodes
%   pour lire une carte de valeurs.
%
%   Exemple :
%      rgb = ind2rgb(round(rand(8) * 63) + 1, jet(64));
%      size(rgb)                       % 8 8 3
%
%   Voir aussi GRAY2RGB, RGB2GRAY, COLORMAP.
    indices = double(indices);
    carte = double(carte);
    if min(indices(:)) >= 0 && max(indices(:)) <= size(carte, 1) - 1
        indices = indices + 1;
    end
    indices = max(1, min(size(carte, 1), round(indices)));
    d = size(indices);
    rgb = zeros([d 3]);
    for plan = 1:3
        valeurs = carte(:, plan);
        rgb(:, :, plan) = reshape(valeurs(indices), d);
    end
end
