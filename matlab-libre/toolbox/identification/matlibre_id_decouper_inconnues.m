function [x0, B, D] = matlibre_id_decouper_inconnues(vecteur, ordre, entrees, sorties)
%MATLIBRE_ID_DECOUPER_INCONNUES Redécoupe le vecteur des inconnues.
%   [X0,B,D] = MATLIBRE_ID_DECOUPER_INCONNUES(V,ORDRE,ENTREES,SORTIES)
%   sépare l'état initial, la matrice d'entrée et la transmission directe.
%
%   Exemple :
%      [x0, B, D] = matlibre_id_decouper_inconnues((1:4)', 2, 1, 1);
%
%   Voir aussi MATLIBRE_ID_ENTREE_SORTIE.
    vecteur = vecteur(:);
    x0 = vecteur(1:ordre);
    position = ordre;
    B = reshape(vecteur((position + 1):(position + ordre * entrees)), ordre, entrees);
    position = position + ordre * entrees;
    D = reshape(vecteur((position + 1):(position + sorties * entrees)), sorties, entrees);
end
