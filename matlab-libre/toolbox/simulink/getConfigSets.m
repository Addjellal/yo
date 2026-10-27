function noms = getConfigSets(modele)
%GETCONFIGSETS Les noms des jeux de configuration d'un modèle.
%   NOMS = GETCONFIGSETS(MODELE) rend la colonne des noms des jeux de
%   configuration du modèle chargé, dans l'ordre où ils lui ont été
%   attachés : 'Configuration' d'abord.
%
%   Exemple :
%      new_system('plusieurs');
%      cs = Simulink.ConfigSet;
%      cs.Name = 'Rapide';
%      attachConfigSet('plusieurs', cs);
%      getConfigSets('plusieurs')               % {'Configuration'; 'Rapide'}
%      bdclose('plusieurs');
%
%   Voir aussi GETCONFIGSET, ATTACHCONFIGSET, SETACTIVECONFIGSET.
    noms = matlibre_sl_jeux('noms', modele);
end
