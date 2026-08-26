function sortie = windowLevel(image, centre, largeur)
%WINDOWLEVEL Fenêtrage densitométrique, comme sur une console de scanner.
    bas = centre - largeur / 2;
    haut = centre + largeur / 2;
    sortie = (double(image) - bas) / max(haut - bas, eps);
    sortie = max(0, min(1, sortie));
end
