function p = matlibre_id_aplatir_etat(modele)
%MATLIBRE_ID_APLATIR_ETAT Matrices d'un modèle d'état, mises à la file.
%   P = MATLIBRE_ID_APLATIR_ETAT(MODELE) empile A, B, C, D et l'état
%   initial en un seul vecteur, celui que l'optimiseur fait varier.
%
%   Exemple :
%      p = matlibre_id_aplatir_etat(n4sid(z, 2));
%
%   Voir aussi SSEST, MATLIBRE_ID_REPLIER_ETAT.
    p = [modele.A(:); modele.B(:); modele.C(:); modele.D(:); modele.x0(:)];
end
