function indicateur = healthIndicator(donnees)
%HEALTHINDICATOR Indicateur de santé : première composante principale
%   des descripteurs, normalisée entre 0 et 1.
    [~, scores] = pca(donnees);
    premiere = scores(:, 1);
    indicateur = rescale(premiere);
    if indicateur(end) < indicateur(1)
        indicateur = 1 - indicateur;
    end
end
