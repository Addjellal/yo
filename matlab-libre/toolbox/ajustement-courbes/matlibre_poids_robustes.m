function poids = matlibre_poids_robustes(residus, nombreParametres, reglage)
%MATLIBRE_POIDS_ROBUSTES Poids déduits des résidus.
%   P = MATLIBRE_POIDS_ROBUSTES(RESIDUS,NOMBREPARAMETRES,REGLAGE) rend le
%   poids de chaque observation. L'échelle est estimée par l'écart absolu
%   médian, divisé par 0,6745 pour qu'il coïncide avec l'écart type sur
%   des données gaussiennes — une estimation que quelques valeurs
%   aberrantes ne déplacent pas.
%
%   Exemple :
%      matlibre_poids_robustes([0.1; 0.1; 10], 1, matlibre_reglage_robuste('bisquare'))
%
%   Voir aussi MATLIBRE_AJUSTER_LINEAIRE, ROBUSTFIT.
    residus = residus(:);
    n = numel(residus);
    echelle = median(abs(residus - median(residus))) / 0.6745;
    if echelle < eps
        echelle = max(std(residus), eps);
    end
    % La correction par les degrés de liberté évite de sous-estimer
    % l'échelle quand le modèle a beaucoup de paramètres.
    correction = sqrt(max(n - nombreParametres, 1) / max(n, 1));
    normalises = residus ./ (reglage.constante * echelle * correction);
    switch reglage.genre
        case 'bisquare'
            poids = (1 - normalises .^ 2) .^ 2;
            poids(abs(normalises) >= 1) = 0;
        case 'lar'
            poids = 1 ./ max(abs(residus), eps * max(1, max(abs(residus))));
            poids = poids / max(poids);
    end
end
