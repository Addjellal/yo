function majoration = matlibre_majoration_bale(x, N, p)
%MATLIBRE_MAJORATION_BALE Facteur de majoration du capital, zone jaune.
%   Le comité de Bâle majore le multiplicateur de capital par paliers,
%   selon le nombre de dépassements observés sur deux cent cinquante
%   jours. La règle est ici transposée au nombre d'observations réel, par
%   la répartition binomiale.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    paliers = [0.95 0.9899 0.9974 0.9995 0.99993 0.999997 1.1];
    valeurs = [0 0.40 0.50 0.65 0.75 0.85 1.00];
    probabilite = matlibre_binomiale_cumulee(x, N, p);
    majoration = 0;
    for k = 1:numel(paliers)
        if probabilite >= paliers(k)
            majoration = valeurs(min(k + 1, numel(valeurs)));
        end
    end
end
