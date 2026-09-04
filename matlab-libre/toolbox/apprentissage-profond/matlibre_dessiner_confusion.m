function matlibre_dessiner_confusion(matrice, classes, titre)
%MATLIBRE_DESSINER_CONFUSION Dessine une matrice de confusion.
%   MATLIBRE_DESSINER_CONFUSION(MATRICE,CLASSES,TITRE) trace la matrice en
%   fausses couleurs et écrit l'effectif dans chaque case. Le texte est
%   clair sur les cases foncées, sombre sur les claires, pour rester
%   lisible partout.
%
%   Exemple :
%      matlibre_dessiner_confusion([2 0; 1 3], {'a','b'}, 'essai');
%
%   Voir aussi CONFUSIONCHART.
    figure();
    imagesc(matrice);
    colorbar();
    n = numel(classes);
    set(gca, 'XTick', 1:n, 'XTickLabel', classes, ...
             'YTick', 1:n, 'YTickLabel', classes);
    xlabel('classe prédite');
    ylabel('classe réelle');
    title(titre);
    seuil = max(matrice(:)) / 2;
    for i = 1:size(matrice, 1)
        for j = 1:size(matrice, 2)
            if matrice(i, j) >= seuil
                couleur = [1 1 1];
            else
                couleur = [0 0 0];
            end
            if matrice(i, j) == round(matrice(i, j))
                texte = sprintf('%d', matrice(i, j));
            else
                texte = sprintf('%.2f', matrice(i, j));
            end
            text(j, i, texte, 'Color', couleur, ...
                 'HorizontalAlignment', 'center');
        end
    end
end
