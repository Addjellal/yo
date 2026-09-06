function [z, mu, sigma] = zscore(x)
%ZSCORE Centrage et réduction colonne par colonne.
%   Z = ZSCORE(X) retranche la moyenne et divise par l'écart type de
%   chaque colonne : le résultat est de moyenne nulle et d'écart type un.
%
%   C'est le préalable de toute méthode qui compare des variables
%   d'unités différentes — analyse en composantes principales,
%   classification, régression pénalisée. Sans lui, la variable exprimée
%   en millimètres écrase celle exprimée en mètres.
%
%   Une colonne constante a un écart type nul : la division la laisse à
%   zéro plutôt que de rendre des infinis.
%
%   Exemple :
%      z = zscore([1 100; 2 200; 3 300]);
%      max(abs(mean(z)))               % 0
%      std(z)                          % [1 1]
%
%   Voir aussi NORMALIZE, PCA, STD.
    if isvector(x)
        mu = mean(x);
        sigma = std(x);
        if sigma == 0
            sigma = 1;
        end
        z = (x - mu) ./ sigma;
        return;
    end
    mu = mean(x);
    sigma = std(x);
    z = zeros(size(x));
    for j = 1:size(x, 2)
        s = sigma(j);
        if s == 0
            s = 1;
        end
        z(:, j) = (x(:, j) - mu(j)) / s;
    end
end
