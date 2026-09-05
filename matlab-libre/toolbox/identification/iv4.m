function modele = iv4(donnees, ordres)
%IV4 Estimation ARX par variables instrumentales, en quatre passes.
%   M = IV4(Z,[na nb nk]) estime un modèle ARX sans le biais que l'ARX
%   ordinaire subit quand le bruit n'est pas blanc.
%
%   Le biais de l'ARX vient de ce que ses régresseurs — les sorties
%   passées — sont corrélés au bruit. La méthode des variables
%   instrumentales les remplace, dans les équations normales, par des
%   grandeurs qui expliquent la sortie sans dépendre du bruit : la sortie
%   simulée par un premier modèle. Quatre passes suffisent, la dernière
%   filtrant les signaux par le modèle du bruit pour approcher la
%   précision optimale.
%
%   Exemple :
%      rng(1);
%      u = sign(randn(1000, 1));
%      y = filter([0 0.5], [1 -0.8], u) + 0.3 * randn(1000, 1);
%      m = iv4(iddata(y, u), [1 1 1]);
%      m.A      % plus proche de 1 -0.8 que ne l'est arx
%
%   Voir aussi ARX, ARMAX, OE, POLYEST.
    ordres = matlibre_id_ordres(ordres, [1 1 0 0 0 1]);
    ordres(3:5) = 0;
    donnees = iddata(donnees);
    jeu = matlibre_id_experience(donnees, 1);
    y = jeu.OutputData;
    u = jeu.InputData;
    % Première passe : un ARX ordinaire, biaisé mais utilisable comme
    % générateur d'instruments.
    premier = matlibre_id_moindres_carres(jeu, ordres, 'arx');
    modele = premier;
    for passe = 2:4
        instrument = filter(modele.B, modele.A, u);
        if passe == 4
            % Dernière passe : les signaux sont filtrés par le modèle du
            % bruit, estimé sur les résidus. C'est ce filtrage qui rend
            % l'estimateur asymptotiquement le plus précis de sa classe.
            residus = matlibre_id_erreurs(modele, y, u);
            bruit = matlibre_id_moindres_carres(iddata(residus, [], jeu.Ts), ...
                                                [max(ordres(1), 1) 0 0 0 0 0], 'ar');
            yFiltre = filter(bruit.A, 1, y);
            uFiltre = filter(bruit.A, 1, u);
            instrumentFiltre = filter(bruit.A, 1, instrument);
        else
            yFiltre = y;
            uFiltre = u;
            instrumentFiltre = instrument;
        end
        theta = matlibre_id_variables_instrumentales(yFiltre, uFiltre, ...
                                                     instrumentFiltre, ordres);
        modele = setpvec(matlibre_id_squelette(ordres, jeu.Ts), theta);
    end
    residus = matlibre_id_erreurs(modele, y, u);
    modele.NoiseVariance = sum(residus .^ 2) / max(numel(residus) - numel(theta), 1);
    modele = matlibre_id_rapport(modele, jeu, 'iv4', numel(residus), numel(theta));
end
