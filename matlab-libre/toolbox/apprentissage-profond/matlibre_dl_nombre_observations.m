function n = matlibre_dl_nombre_observations(donnees)
%MATLIBRE_DL_NOMBRE_OBSERVATIONS Effectif d'un tableau de données.
%   N = MATLIBRE_DL_NOMBRE_OBSERVATIONS(D) rend la taille de la dernière
%   dimension, où se rangent les observations par convention.
%
%   Exemple :
%      matlibre_dl_nombre_observations(zeros(8, 8, 1, 30))      % 30
%
%   Voir aussi MINIBATCHQUEUE.
    taille = size(matlibre_dl_valeur(donnees));
    n = taille(end);
end
