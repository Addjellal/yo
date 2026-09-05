function sortie = matlibre_id_predire(modele, donnees, horizon)
%MATLIBRE_ID_PREDIRE Prédiction à K pas d'un modèle polynomial.
%   Z = MATLIBRE_ID_PREDIRE(MODELE,DONNEES,HORIZON) rend la prédiction de
%   la sortie connaissant le passé jusqu'à HORIZON pas en arrière.
%
%   Le prédicteur s'écrit ŷ = y - W(q) e, où e est l'erreur à un pas et W
%   les HORIZON premiers termes de la réponse du filtre de bruit. À un
%   pas, W vaut un et l'on retrouve ŷ = y - e ; à l'infini, W est le
%   filtre entier et la prédiction devient la simulation, qui n'utilise
%   plus la sortie mesurée du tout.
%
%   Exemple :
%      m = arx(z, [2 2 1]);
%      zp = predict(m, z, 1);
%
%   Voir aussi SIM, COMPARE, FORECAST.
    [y, u, jeu] = matlibre_id_extraire_voies(donnees);
    if isinf(horizon)
        prediction = filter(modele.B, conv(modele.A, modele.F), u);
    else
        e = matlibre_id_erreurs(modele, y, u);
        W = matlibre_id_reponse_bruit(modele, max(1, round(horizon)));
        prediction = y - filter(W, 1, e);
    end
    sortie = jeu;
    sortie.OutputData = prediction;
end
