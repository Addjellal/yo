function noms = getConfigSets(modele)
%GETCONFIGSETS Les noms des jeux de configuration d'un modèle.
%   NOMS = GETCONFIGSETS(MODELE) rend en colonne les noms des jeux du
%   modèle, le jeu actif d'abord. MODELE est le nom d'un modèle de la
%   session, ou un modèle par valeur.
%
%   Exemple :
%      m = new_system('essai');
%      getConfigSets(m)                         % {'Configuration'}
%
%   Voir aussi GETCONFIGSET, GETACTIVECONFIGSET, ATTACHCONFIGSET.
    parNom = ~isstruct(modele);
    if parNom
        [modele, nomModele] = matlibre_sl_nomme('modele', modele);
    end
    noms = matlibre_sl_jeux('noms', modele);
end
