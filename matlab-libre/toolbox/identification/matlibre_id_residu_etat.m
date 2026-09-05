function e = matlibre_id_residu_etat(p, modeleForme, y, u)
%MATLIBRE_ID_RESIDU_ETAT Erreur de simulation d'un modèle d'état.
%   E = MATLIBRE_ID_RESIDU_ETAT(P,FORME,Y,U) reconstruit le modèle depuis
%   le vecteur de paramètres et rend l'écart entre la sortie mesurée et la
%   sortie simulée.
%
%   Exemple :
%      % appelée par l'optimiseur, jamais directement
%
%   Voir aussi SSEST.
    modele = matlibre_id_replier_etat(p, modeleForme);
    simulee = matlibre_id_parcourir_etat(modele, u, modele.x0);
    e = y(:) - simulee(:);
end
