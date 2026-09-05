function prediction = matlibre_id_filtrer_etat(modele, y, u, horizon)
%MATLIBRE_ID_FILTRER_ETAT Prédiction à K pas d'un modèle d'état bruité.
%   P = MATLIBRE_ID_FILTRER_ETAT(MODELE,Y,U,HORIZON) corrige l'état par
%   l'innovation à chaque instant — c'est le gain de Kalman qui pèse cette
%   correction —, puis fait avancer le modèle HORIZON pas sans correction.
%
%   Exemple :
%      p = matlibre_id_filtrer_etat(m, y, u, 1);
%
%   Voir aussi IDSS, PREDICT.
    n = size(y, 1);
    sorties = size(modele.C, 1);
    prediction = zeros(n, sorties);
    x = modele.x0(:);
    etats = zeros(n, numel(x));
    for t = 1:n
        etats(t, :) = x.';
        innovation = y(t, :).' - (modele.C * x + modele.D * u(t, :).');
        x = modele.A * x + modele.B * u(t, :).' + modele.K * innovation;
    end
    for t = 1:n
        depart = max(t - horizon + 1, 1);
        x = etats(depart, :).';
        for s = depart:(t - 1)
            x = modele.A * x + modele.B * u(s, :).';
        end
        prediction(t, :) = (modele.C * x + modele.D * u(t, :).').';
    end
end
