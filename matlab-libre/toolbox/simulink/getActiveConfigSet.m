function cs = getActiveConfigSet(modele)
%GETACTIVECONFIGSET Le jeu de configuration actif d'un modèle.
%   CS = GETACTIVECONFIGSET(MODELE) rend le Simulink.ConfigSet que la
%   simulation de MODELE emploie — un modèle chargé, désigné par son nom
%   ou sa poignée. SET_PARAM(CS,...) change aussitôt les réglages du
%   modèle, GET_PARAM(CS,...) les lit ; deux appels rendent la même
%   poignée.
%
%   CS = GETACTIVECONFIGSET(M), M un modèle tenu dans une variable, rend
%   une copie détachée de ses réglages.
%
%   Exemple :
%      new_system('actif');
%      cs = getActiveConfigSet('actif');
%      set_param(cs, 'StopTime', '3');
%      get_param('actif', 'StopTime')           % '3'
%      cs == getActiveConfigSet('actif')        % vrai : le même jeu
%      bdclose('actif');
%
%   Voir aussi SIMULINK.CONFIGSET, GETCONFIGSET, SETACTIVECONFIGSET,
%   ATTACHCONFIGSET.
    if isstruct(modele)
        cs = Simulink.ConfigSet;
        if isfield(modele, 'jeuActif') && ~isempty(modele.jeuActif)
            cs.Name = modele.jeuActif;
        end
        if isfield(modele, 'parametres') && isstruct(modele.parametres)
            cs.Reglages = modele.parametres;
        end
        return
    end
    nom = matlibre_sl_memoire('chemin', modele);
    cs = matlibre_sl_jeux('objet', nom, matlibre_sl_jeux('actif', nom));
end
