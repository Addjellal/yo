function oui = existsInGlobal(modele, nom)
%EXISTSINGLOBAL Dit si une variable existe là où les blocs d'un modèle la lisent.
%   OUI = SIMULINK.DATA.EXISTSINGLOBAL(MODELE,NOM) cherche NOM dans la
%   section 'Design Data' du dictionnaire de données du modèle chargé
%   MODELE (son réglage DataDictionary) et dans les dictionnaires qu'il
%   référence, puis dans l'espace de travail de base — sauf quand le
%   modèle a un dictionnaire et EnableAccessToBaseWorkspace à 'off'.
%
%   Exemple :
%      new_system('globalExiste');
%      assignin('base', 'gainGlobal', 2);
%      Simulink.data.existsInGlobal('globalExiste', 'gainGlobal')   % true
%      evalin('base', 'clear gainGlobal');
%      close_system('globalExiste', 0);
%
%   Voir aussi SIMULINK.DATA.EVALINGLOBAL, SIMULINK.DATA.ASSIGNINGLOBAL.
    [dictionnaire, base] = matlibre_sl_portee(modele);
    nom = char(nom);
    oui = false;
    if ~isempty(dictionnaire)
        oui = matlibre_sl_dictionnaire('existe', dictionnaire, 'Design Data', nom);
    end
    if ~oui && base && isvarname(nom)
        oui = evalin('base', sprintf('exist(''%s'', ''var'')', nom)) == 1;
    end
end
