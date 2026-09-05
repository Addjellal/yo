function ordre = matlibre_id_ordre_conseille(jeu)
%MATLIBRE_ID_ORDRE_CONSEILLE Ordre que les données semblent demander.
%   N = MATLIBRE_ID_ORDRE_CONSEILLE(JEU) essaie les ordres de un à cinq et
%   rend celui dont le critère d'erreur finale de prédiction est le plus
%   petit.
%
%   Exemple :
%      matlibre_id_ordre_conseille(jeu)
%
%   Voir aussi ADVICE, FPE, ARX.
    ordre = 1;
    meilleur = Inf;
    for n = 1:5
        try
            modele = arx(jeu, [n, n, 1]);
        catch
            break
        end
        critere = modele.Report.Fit.FPE;
        if critere < meilleur
            meilleur = critere;
            ordre = n;
        end
    end
end
