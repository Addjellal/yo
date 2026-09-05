function modele = matlibre_id_replier_etat(p, modeleForme)
%MATLIBRE_ID_REPLIER_ETAT Reconstruit un modèle d'état depuis un vecteur.
%   MODELE = MATLIBRE_ID_REPLIER_ETAT(P,FORME) redécoupe le vecteur selon
%   les tailles du modèle donné pour modèle.
%
%   Exemple :
%      m = matlibre_id_replier_etat(p, depart);
%
%   Voir aussi SSEST, MATLIBRE_ID_APLATIR_ETAT.
    modele = modeleForme;
    tailleA = size(modeleForme.A);
    tailleB = size(modeleForme.B);
    tailleC = size(modeleForme.C);
    tailleD = size(modeleForme.D);
    position = 0;
    modele.A = reshape(p((position + 1):(position + prod(tailleA))), tailleA);
    position = position + prod(tailleA);
    modele.B = reshape(p((position + 1):(position + prod(tailleB))), tailleB);
    position = position + prod(tailleB);
    modele.C = reshape(p((position + 1):(position + prod(tailleC))), tailleC);
    position = position + prod(tailleC);
    modele.D = reshape(p((position + 1):(position + prod(tailleD))), tailleD);
    position = position + prod(tailleD);
    modele.x0 = p((position + 1):end);
end
