function modele = matlibre_id_meilleur_ordre(donnees, fabrique)
%MATLIBRE_ID_MEILLEUR_ORDRE Ordre qui minimise le critère de prédiction.
%   M = MATLIBRE_ID_MEILLEUR_ORDRE(DONNEES,FABRIQUE) essaie les ordres de
%   un à dix et garde celui dont le critère d'erreur finale de prédiction
%   est le plus petit — critère qui pénalise le nombre de paramètres, sans
%   quoi le plus grand ordre gagnerait toujours.
%
%   Exemple :
%      m = n4sid(z, 'best');
%
%   Voir aussi N4SID, SSEST, FPE.
    meilleur = [];
    meilleurCritere = Inf;
    for ordre = 1:10
        try
            courant = fabrique(ordre);
        catch
            break
        end
        critere = courant.Report.Fit.FPE;
        if critere < meilleurCritere
            meilleurCritere = critere;
            meilleur = courant;
        end
    end
    if isempty(meilleur)
        error('ident:ordre:Aucun', 'Aucun ordre n''a pu être estimé.');
    end
    modele = meilleur;
end
