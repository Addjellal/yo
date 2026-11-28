function cs = getConfigSet(modele, nom)
%GETCONFIGSET Un jeu de configuration d'un modèle, par son nom.
%   CS = GETCONFIGSET(MODELE,NOM) rend le Simulink.ConfigSet nommé NOM
%   parmi ceux du modèle, actif ou non. Pour un modèle de la session,
%   désigné par son nom, le jeu y reste lié ; pour un modèle par valeur,
%   c'est une copie.
%
%   Exemple :
%      m = new_system('essai');
%      cs = Simulink.ConfigSet;
%      cs.Name = 'Rapide';
%      m = attachConfigSet(m, cs);
%      get_param(getConfigSet(m, 'Rapide'), 'StopTime')     % '10'
%
%   Voir aussi GETCONFIGSETS, GETACTIVECONFIGSET, ATTACHCONFIGSET.
    parNom = ~isstruct(modele);
    if parNom
        [modele, nomModele] = matlibre_sl_nomme('modele', modele);
    end
    jeu = matlibre_sl_jeux('lire', modele, char(nom));
    if parNom
        cs = Simulink.ConfigSet(jeu, nomModele);
    else
        cs = Simulink.ConfigSet(jeu);
    end
end
