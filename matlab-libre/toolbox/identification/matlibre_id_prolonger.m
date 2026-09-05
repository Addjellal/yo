function sortie = matlibre_id_prolonger(modele, donnees, horizon)
%MATLIBRE_ID_PROLONGER Prolonge des données au-delà de leur fin.
%   Z = MATLIBRE_ID_PROLONGER(MODELE,DONNEES,HORIZON) rend les HORIZON
%   valeurs à venir. Le passé mesuré sert d'état initial ; l'avenir est
%   calculé en supposant le bruit nul, ce qui est son espérance — la
%   prévision est donc la moyenne conditionnelle, pas une trajectoire
%   possible.
%
%   Exemple :
%      m = ar(iddata(y), 2);
%      zf = forecast(m, iddata(y), 10);
%
%   Voir aussi PREDICT, SIM, AR.
    [y, u, jeu] = matlibre_id_extraire_voies(donnees);
    horizon = round(horizon);
    n = numel(y);
    e = matlibre_id_erreurs(modele, y, u);
    % On prolonge en gardant l'entrée à sa dernière valeur et le bruit à
    % zéro, puis on recalcule la sortie de proche en proche.
    uEtendu = [u; repmat(u(end), horizon, 1)];
    eEtendu = [e; zeros(horizon, 1)];
    yEtendu = [y; zeros(horizon, 1)];
    for t = (n + 1):(n + horizon)
        yEtendu(t) = matlibre_id_pas_suivant(modele, yEtendu, uEtendu, eEtendu, t);
    end
    sortie = jeu;
    sortie.OutputData = yEtendu((n + 1):end);
    if ~isempty(jeu.InputData)
        sortie.InputData = uEtendu((n + 1):end);
    end
end

function valeur = matlibre_id_pas_suivant(modele, y, u, e, t)
% La récurrence du modèle, résolue pour la sortie à l'instant t.
    entree = filter(modele.B, modele.F, u(1:t));
    bruit = filter(modele.C, modele.D, e(1:t));
    passe = 0;
    for k = 2:numel(modele.A)
        if t - k + 1 >= 1
            passe = passe + modele.A(k) * y(t - k + 1);
        end
    end
    valeur = (entree(t) + bruit(t) - passe) / modele.A(1);
end
