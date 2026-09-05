function sortie = matlibre_id_predire_etat(modele, donnees, horizon)
%MATLIBRE_ID_PREDIRE_ETAT Prédiction d'un modèle d'état.
%   Z = MATLIBRE_ID_PREDIRE_ETAT(MODELE,DONNEES,HORIZON) rend la sortie
%   prédite. Avec un gain de Kalman nul, la prédiction est la simulation,
%   quel que soit l'horizon : le modèle n'a alors aucun moyen de corriger
%   son état par la sortie mesurée.
%
%   Exemple :
%      zp = predict(m, z, 1);
%
%   Voir aussi IDSS, PREDICT, N4SID.
    [y, u, jeu] = matlibre_id_extraire_voies(donnees);
    if all(modele.K(:) == 0) || isinf(horizon)
        prediction = matlibre_id_parcourir_etat(modele, u, modele.x0);
    else
        prediction = matlibre_id_filtrer_etat(modele, y, u, round(horizon));
    end
    sortie = jeu;
    sortie.OutputData = prediction;
end
