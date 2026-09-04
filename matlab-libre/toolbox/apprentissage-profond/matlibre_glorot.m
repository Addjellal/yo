function W = matlibre_glorot(taille, entrees, sorties)
%MATLIBRE_GLOROT Tirage initial des poids d'une couche.
%   W = MATLIBRE_GLOROT(TAILLE,ENTREES,SORTIES) tire uniformément dans
%   l'intervalle de demi-largeur racine de six sur la somme du nombre
%   d'entrées et de sorties.
%
%   Ce choix conserve la variance du signal en traversant la couche, dans
%   les deux sens : sans lui, les activations d'un réseau profond enflent
%   ou s'éteignent d'une couche à l'autre, et le gradient avec elles.
%
%   Exemple :
%      W = matlibre_glorot([3 4], 4, 3);
%      max(abs(W(:))) <= sqrt(6 / 7)      % vrai
%
%   Voir aussi MATLIBRE_COUCHE_INITIALISER, DLNETWORK.
    limite = sqrt(6 / (entrees + sorties));
    W = (rand(taille) * 2 - 1) * limite;
end
