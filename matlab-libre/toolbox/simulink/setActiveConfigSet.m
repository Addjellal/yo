function modele = setActiveConfigSet(modele, nom)
%SETACTIVECONFIGSET Rend actif un jeu de configuration du modèle.
%   SETACTIVECONFIGSET(MODELE,NOM) active le jeu nommé NOM du modèle de
%   la session nommé MODELE : ses réglages deviennent ceux du modèle —
%   ceux que GET_PARAM lit et que SIM applique —, et ceux du jeu qui
%   était actif attendent d'être réactivés.
%
%   MODELE = SETACTIVECONFIGSET(MODELE,NOM) fait de même sur un modèle
%   par valeur, et le rend.
%
%   Exemple :
%      m = new_system('essai');
%      cs = Simulink.ConfigSet;
%      cs.Name = 'Rapide';
%      set_param(cs, 'StopTime', '1');
%      m = setActiveConfigSet(attachConfigSet(m, cs), 'Rapide');
%      get_param(m, 'StopTime')                 % 1
%      m = setActiveConfigSet(m, 'Configuration');
%      get_param(m, 'StopTime')                 % 10
%
%   Voir aussi GETACTIVECONFIGSET, ATTACHCONFIGSET, GETCONFIGSETS.
    parNom = ~isstruct(modele);
    if parNom
        [modele, nomModele] = matlibre_sl_nomme('modele', modele);
    end
    modele = matlibre_sl_jeux('activer', modele, char(nom));
    if parNom
        matlibre_sl_nomme('ranger', nomModele, modele);
        clear modele
    end
end
