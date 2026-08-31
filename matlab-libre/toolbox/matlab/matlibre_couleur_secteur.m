function couleur = matlibre_couleur_secteur(k)
%MATLIBRE_COULEUR_SECTEUR La k-ième couleur de la palette des secteurs.
%   Fonction interne : elle n'existe pas dans MATLAB. PIE, PIE3 et ROSE
%   s'en servent pour que deux secteurs voisins se distinguent, sans
%   dépendre de la palette des courbes, qui n'a que sept tons.
    palette = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13;
               0.49 0.18 0.56; 0.47 0.67 0.19; 0.30 0.75 0.93;
               0.64 0.08 0.18; 0.40 0.40 0.40; 0.20 0.60 0.50;
               0.80 0.60 0.70];
    couleur = palette(mod(k - 1, size(palette, 1)) + 1, :);
end
