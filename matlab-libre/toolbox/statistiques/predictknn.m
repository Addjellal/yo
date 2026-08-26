function etiquettes = predictknn(modele, Xnouveau)
%PREDICTKNN Prédiction d'un classifieur k plus proches voisins.
    [indices, ~] = knnsearch(modele.X, Xnouveau, 'K', modele.K);
    m = size(Xnouveau, 1);
    etiquettes = zeros(m, 1);
    for i = 1:m
        voisins = modele.Y(indices(i, :));
        etiquettes(i) = mode(voisins);
    end
end
