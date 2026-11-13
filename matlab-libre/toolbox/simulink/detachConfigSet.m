function varargout = detachConfigSet(modele, nom)
%DETACHCONFIGSET Détache un jeu de configuration d'un modèle.
%   CS = DETACHCONFIGSET(MODELE,NOM) retire du modèle de la session nommé
%   MODELE le jeu nommé NOM, et le rend, libre. Le jeu actif ne se
%   détache pas : il faut d'abord en activer un autre.
%
%   [MODELE,CS] = DETACHCONFIGSET(MODELE,NOM) fait de même sur un modèle
%   par valeur.
%
%   Exemple :
%      m = new_system('essai');
%      cs = Simulink.ConfigSet;
%      cs.Name = 'Rapide';
%      m = attachConfigSet(m, cs);
%      [m, libre] = detachConfigSet(m, 'Rapide');
%      getConfigSets(m)                         % {'Configuration'}
%
%   Voir aussi ATTACHCONFIGSET, SETACTIVECONFIGSET, GETCONFIGSETS.
    parNom = ~isstruct(modele);
    if parNom
        [modele, nomModele] = matlibre_sl_nomme('modele', modele);
    end
    cs = Simulink.ConfigSet(matlibre_sl_jeux('lire', modele, char(nom)));
    modele = matlibre_sl_jeux('detacher', modele, char(nom));
    if parNom
        matlibre_sl_nomme('ranger', nomModele, modele);
        varargout = {cs};
    else
        varargout = {modele, cs};
    end
end
