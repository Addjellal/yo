function setActiveConfigSet(modele, nom)
%SETACTIVECONFIGSET Choisit le jeu de configuration qu'emploie un modèle.
%   SETACTIVECONFIGSET(MODELE,NOM) fait du jeu NOM, attaché au modèle
%   chargé, le jeu actif : la simulation prend ses réglages, et l'ancien
%   jeu actif garde les siens, prêt à être réactivé.
%
%   Exemple :
%      new_system('bascule');
%      cs = Simulink.ConfigSet;
%      cs.Name = 'Court';
%      set_param(cs, 'StopTime', '1');
%      attachConfigSet('bascule', cs);
%      setActiveConfigSet('bascule', 'Court');
%      get_param('bascule', 'StopTime')         % '1'
%      setActiveConfigSet('bascule', 'Configuration');
%      get_param('bascule', 'StopTime')         % '10', le défaut
%      bdclose('bascule');
%
%   Voir aussi GETACTIVECONFIGSET, ATTACHCONFIGSET, GETCONFIGSETS.
    if isstring(nom) && isscalar(nom)
        nom = char(nom);
    end
    if isa(nom, 'Simulink.ConfigSet')
        nom = nom.Name;
    end
    matlibre_sl_jeux('activer', modele, nom);
end
