function cs = getActiveConfigSet(modele)
%GETACTIVECONFIGSET Le jeu de configuration actif d'un modèle.
%   CS = GETACTIVECONFIGSET(MODELE) rend le Simulink.ConfigSet actif du
%   modèle : ses réglages sont ceux que SIM applique. MODELE est le nom
%   d'un modèle de la session — le jeu y reste alors lié, et
%   SET_PARAM(CS,...) règle le modèle — ou un modèle par valeur, dont le
%   jeu rendu est une copie.
%
%   Exemple :
%      bdclose('all');
%      new_system('essai');
%      cs = getActiveConfigSet('essai');
%      set_param(cs, 'StopTime', '5');
%      get_param('essai', 'StopTime')           % '5'
%      bdclose('all');
%
%   Voir aussi SIMULINK.CONFIGSET, GETCONFIGSETS, SETACTIVECONFIGSET,
%   ATTACHCONFIGSET.
    parNom = ~isstruct(modele);
    if parNom
        [modele, nomModele] = matlibre_sl_nomme('modele', modele);
    end
    jeu = matlibre_sl_jeux('lire', modele, matlibre_sl_jeux('actif', modele));
    if parNom
        cs = Simulink.ConfigSet(jeu, nomModele);
    else
        cs = Simulink.ConfigSet(jeu);
    end
end
