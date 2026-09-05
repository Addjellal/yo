function sortie = matlibre_id_simuler_tf(modele, entree)
%MATLIBRE_ID_SIMULER_TF Simule une fonction de transfert estimée.
%   Z = MATLIBRE_ID_SIMULER_TF(MODELE,ENTREE) applique le modèle à
%   l'entrée. Un modèle continu est d'abord discrétisé à la période des
%   données, par blocage d'ordre zéro — l'entrée d'un enregistrement étant
%   constante entre deux mesures, c'est la discrétisation exacte.
%
%   Exemple :
%      z = sim(tfest(donnees, 2, 1), donnees);
%
%   Voir aussi IDTF, TFEST.
    if isa(entree, 'iddata')
        jeu = matlibre_id_experience(entree, 1);
        u = jeu.InputData;
    else
        u = double(entree);
        if isvector(u)
            u = u(:);
        end
        jeu = iddata([], u, modele.Ts);
    end
    periode = jeu.Ts;
    if modele.Ts == 0
        discret = c2d(tf(modele.Numerator, modele.Denominator), periode, 'zoh');
        [numerateur, denominateur] = tfdata(discret, 'v');
    else
        numerateur = modele.Numerator;
        denominateur = modele.Denominator;
    end
    if modele.IODelay ~= 0
        u = matlibre_id_retarder(u, modele.IODelay / periode);
    end
    y = filter(numerateur, denominateur, u);
    sortie = jeu;
    sortie.OutputData = y;
end
