function assigninGlobal(modele, nom, valeur)
%ASSIGNINGLOBAL Pose une variable là où les blocs d'un modèle la lisent.
%   SIMULINK.DATA.ASSIGNINGLOBAL(MODELE,NOM,VALEUR) la pose dans la
%   section 'Design Data' du dictionnaire de données du modèle chargé
%   MODELE — dans le dictionnaire référencé qui la définit, s'il y a lieu
%   —, ou dans l'espace de travail de base quand le modèle n'a pas de
%   dictionnaire. Une variable que le dictionnaire ne porte pas, mais que
%   l'espace de base porte, y change quand EnableAccessToBaseWorkspace
%   vaut 'on'.
%
%   Exemple :
%      new_system('globalPose');
%      Simulink.data.assigninGlobal('globalPose', 'kPose', 4);
%      evalin('base', 'kPose')                % 4
%      evalin('base', 'clear kPose');
%      close_system('globalPose', 0);
%
%   Voir aussi SIMULINK.DATA.EVALINGLOBAL, SIMULINK.DATA.EXISTSINGLOBAL.
    [dictionnaire, base] = matlibre_sl_portee(modele);
    nom = char(nom);
    if ~isvarname(nom)
        error('Simulink:Data:InvalidVariableName', ...
              '''%s'' n''est pas un nom de variable de MATLAB.', nom);
    end
    if isempty(dictionnaire) || ...
       (base && ~matlibre_sl_dictionnaire('existe', dictionnaire, 'Design Data', nom) && ...
        evalin('base', sprintf('exist(''%s'', ''var'')', nom)) == 1)
        assignin('base', nom, valeur);
    else
        matlibre_sl_dictionnaire('ecrire', dictionnaire, 'Design Data', nom, valeur);
    end
end
