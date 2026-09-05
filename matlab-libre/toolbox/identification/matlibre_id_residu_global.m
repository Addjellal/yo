function e = matlibre_id_residu_global(p, squelette, donnees)
%MATLIBRE_ID_RESIDU_GLOBAL Erreurs de prédiction, toutes expériences.
%   E = MATLIBRE_ID_RESIDU_GLOBAL(P,SQUELETTE,DONNEES) pose les paramètres
%   dans le modèle et empile les erreurs de chaque expérience.
%
%   Exemple :
%      % appelée par l'optimiseur, jamais directement
%
%   Voir aussi MATLIBRE_ID_ESTIMER.
    modele = setpvec(squelette, p);
    experiences = matlibre_id_nombre_experiences(donnees);
    morceaux = cell(1, experiences);
    for k = 1:experiences
        jeu = matlibre_id_experience(donnees, k);
        u = jeu.InputData;
        if isempty(u)
            u = zeros(size(jeu.OutputData));
        end
        morceaux{k} = matlibre_id_erreurs(modele, jeu.OutputData, u);
    end
    e = vertcat(morceaux{:});
end
