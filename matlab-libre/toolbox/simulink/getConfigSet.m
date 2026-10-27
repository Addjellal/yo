function cs = getConfigSet(modele, nom)
%GETCONFIGSET Un jeu de configuration d'un modèle, désigné par son nom.
%   CS = GETCONFIGSET(MODELE,NOM) rend le Simulink.ConfigSet nommé NOM du
%   modèle chargé, actif ou non, et [] s'il n'en a pas de ce nom.
%
%   Exemple :
%      new_system('designe');
%      cs = getConfigSet('designe', 'Configuration');
%      get_param(cs, 'Solver')                  % le solveur du modèle
%      isempty(getConfigSet('designe', 'Absent'))   % vrai
%      bdclose('designe');
%
%   Voir aussi GETCONFIGSETS, GETACTIVECONFIGSET, ATTACHCONFIGSET.
    if any(strcmp(matlibre_sl_jeux('noms', modele), char(nom)))
        cs = matlibre_sl_jeux('objet', modele, char(nom));
    else
        cs = [];
    end
end
