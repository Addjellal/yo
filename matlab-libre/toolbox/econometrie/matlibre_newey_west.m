function variance = matlibre_newey_west(residus, retards)
%MATLIBRE_NEWEY_WEST Variance de long terme, fenêtre de Bartlett.
%   La variance d'une somme de termes corrélés n'est pas la somme de
%   leurs variances : il faut y ajouter les covariances, pondérées par
%   une fenêtre qui décroît avec le retard. C'est ce que fait Newey-West,
%   et c'est ce qui rend l'estimation positive.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    residus = double(residus(:));
    n = numel(residus);
    variance = sum(residus .^ 2) / n;
    for j = 1:retards
        poids = 1 - j / (retards + 1);
        covariance = sum(residus(1:(n - j)) .* residus((1 + j):n)) / n;
        variance = variance + 2 * poids * covariance;
    end
end
