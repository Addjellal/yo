function [coefficients, valeurs, expliquee] = pcacov(C)
%PCACOV Composantes principales à partir de la covariance.
%   COEFF = PCACOV(C) rend les composantes principales déduites de la
%   matrice de covariance C, une par colonne, rangées par variance
%   décroissante. C'est PCA quand on n'a plus les données mais seulement
%   leur covariance — ce qui arrive souvent, une covariance étant tout ce
%   qu'un article publie.
%
%   [COEFF,L] = PCACOV(C) rend aussi les variances portées par chaque
%   composante : ce sont les valeurs propres de C.
%
%   [COEFF,L,EXPLIQUEE] = PCACOV(C) rend la part de la variance totale
%   que chaque composante explique, en pour cent.
%
%   Le signe de chaque colonne est fixé comme dans MATLAB : la
%   composante de plus grande valeur absolue est rendue positive, de
%   sorte que deux appels donnent le même résultat.
%
%   PCACOV appliqué à une matrice de corrélation donne l'analyse en
%   composantes principales normée, celle qu'il faut quand les variables
%   n'ont pas la même unité.
%
%   Exemples :
%      X = randn(100, 3) * [1 0 0; 0.5 1 0; 0 0 2];
%      [c1, l1] = pcacov(cov(X));
%      [c2, ~, l2] = pca(X);
%      max(abs(l1 - l2))            % les memes valeurs propres
%
%      pcacov(corrcoef(X))          % l'analyse normee
%
%   Voir aussi PCA, PRINCOMP, COV, CORRCOEF, EIG, CANONCORR.
    if size(C, 1) ~= size(C, 2)
        error('stats:pcacov:BadMatrix', 'The covariance matrix must be square.');
    end
    % La symétrisation ôte le bruit d'arrondi que porte une covariance
    % calculée : sans elle, les valeurs propres peuvent sortir complexes.
    C = (C + C') / 2;
    [V, D] = eig(C);
    valeurs = real(diag(D));
    [valeurs, ordre] = sort(valeurs, 'descend');
    coefficients = real(V(:, ordre));
    for j = 1:size(coefficients, 2)
        [~, dominante] = max(abs(coefficients(:, j)));
        if coefficients(dominante, j) < 0
            coefficients(:, j) = -coefficients(:, j);
        end
    end
    total = sum(valeurs);
    if total == 0
        expliquee = zeros(size(valeurs));
    else
        expliquee = 100 * valeurs / total;
    end
end
