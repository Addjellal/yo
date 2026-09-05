function h = matlibre_id_reponse_bruit(modele, longueur)
%MATLIBRE_ID_REPONSE_BRUIT Réponse impulsionnelle du filtre de bruit.
%   H = MATLIBRE_ID_REPONSE_BRUIT(MODELE,LONGUEUR) rend les premiers
%   termes de la réponse de C/(A D), le filtre qui mène le bruit blanc à
%   la sortie. Ce sont eux qui construisent le prédicteur à plusieurs pas.
%
%   Exemple :
%      matlibre_id_reponse_bruit(idpoly([1 -0.5]), 3)      % 1 0.5 0.25
%
%   Voir aussi PREDICT, FORECAST.
    impulsion = zeros(longueur, 1);
    impulsion(1) = 1;
    h = filter(modele.C, conv(modele.A, modele.D), impulsion);
    h = h(:).';
end
