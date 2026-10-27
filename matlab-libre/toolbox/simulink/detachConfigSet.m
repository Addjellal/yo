function cs = detachConfigSet(modele, nom)
%DETACHCONFIGSET Détache un jeu de configuration d'un modèle.
%   CS = DETACHCONFIGSET(MODELE,NOM) retire le jeu NOM du modèle chargé et
%   le rend, détaché, avec ses réglages : on peut l'attacher à un autre.
%   Le jeu actif ne se détache pas.
%
%   Exemple :
%      new_system('detache');
%      cs = Simulink.ConfigSet;
%      cs.Name = 'Essai';
%      attachConfigSet('detache', cs);
%      libre = detachConfigSet('detache', 'Essai');
%      getConfigSets('detache')                 % {'Configuration'}
%      bdclose('detache');
%
%   Voir aussi ATTACHCONFIGSET, SETACTIVECONFIGSET, GETCONFIGSETS.
    if isstring(nom) && isscalar(nom)
        nom = char(nom);
    end
    cs = matlibre_sl_jeux('detacher', modele, nom);
end
