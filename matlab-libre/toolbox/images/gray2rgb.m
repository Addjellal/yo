function rgb = gray2rgb(g)
%GRAY2RGB Réplique une image en niveaux de gris sur trois canaux.
    [h, l] = size(g);
    rgb = zeros(h, l, 3);
    rgb(:,:,1) = g;
    rgb(:,:,2) = g;
    rgb(:,:,3) = g;
end
