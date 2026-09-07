function indicateur = healthIndicator(donnees)
%HEALTHINDICATOR Indicateur de santé : première composante principale
%   des descripteurs, normalisée entre 0 et 1.
%
%   INDICATEUR = HEALTHINDICATOR(DONNEES) prend une matrice à une ligne
%   par cycle et une colonne par descripteur, et rend une seule courbe.
%
%   Plusieurs descripteurs, une seule courbe : l'analyse en composantes
%   principales trouve la direction où ils varient le plus ensemble, et
%   c'est celle-là qui suit la dégradation. Les descripteurs n'ont pas les
%   mêmes unités ni les mêmes ordres de grandeur, et la normalisation
%   finale rend l'indicateur comparable d'une machine à l'autre.
%
%   L'orientation est fixée : l'indicateur croît toujours, quel que soit
%   le signe des descripteurs. Sans cela un seuil n'aurait pas de sens.
%
%   Il croît par blocs, non à chaque cycle : le bruit de mesure domine les
%   écarts d'un cycle au suivant, et c'est la tendance qui porte
%   l'information.
%
%   Exemple :
%      rng(1);
%      n = 50;
%      efficaces = linspace(1, 2, n)' + 0.01 * randn(n, 1);
%      kurtosis = linspace(3, 5, n)' + 0.01 * randn(n, 1);
%      centroides = linspace(100, 200, n)' + randn(n, 1);
%      sante = healthIndicator([efficaces, kurtosis, centroides]);
%      numel(sante)      % 50
%
%   Voir aussi FAULTFEATURES, RULDEGRADATION, RULSIMILARITY, PCA.
    [~, scores] = pca(donnees);
    premiere = scores(:, 1);
    indicateur = rescale(premiere);
    if indicateur(end) < indicateur(1)
        indicateur = 1 - indicateur;
    end
end
