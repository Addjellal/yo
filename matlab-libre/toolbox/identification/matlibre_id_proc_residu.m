function e = matlibre_id_proc_residu(p, poser, jeu)
%MATLIBRE_ID_PROC_RESIDU Erreur de simulation d'un modèle de procédé.
%   E = MATLIBRE_ID_PROC_RESIDU(P,POSER,JEU) reconstruit le modèle depuis
%   ses paramètres et rend l'écart à la sortie mesurée.
%
%   Exemple :
%      % appelée par l'optimiseur, jamais directement
%
%   Voir aussi PROCEST.
    modele = poser(p);
    modele.Ts = jeu.Ts;
    simulee = matlibre_id_simuler_proc(modele, jeu);
    e = jeu.OutputData - simulee.OutputData;
end
