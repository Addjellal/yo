function varargout = attachConfigSetCopy(modele, cs, renommer)
%ATTACHCONFIGSETCOPY Attache à un modèle la copie d'un jeu de configuration.
%   COPIE = ATTACHCONFIGSETCOPY(MODELE,CS) attache au modèle de la
%   session nommé MODELE une copie du Simulink.ConfigSet CS, et la rend :
%   CS lui-même reste où il était — libre, ou attaché à un autre modèle.
%   ATTACHCONFIGSETCOPY(MODELE,CS,true) renomme la copie si le nom est pris.
%
%   [MODELE,COPIE] = ATTACHCONFIGSETCOPY(MODELE,CS) fait de même sur un
%   modèle par valeur.
%
%   Exemple :
%      bdclose('all');
%      new_system('un');
%      new_system('deux');
%      cs = getActiveConfigSet('un');
%      set_param(cs, 'StopTime', '7');
%      copie = attachConfigSetCopy('deux', cs, true);
%      setActiveConfigSet('deux', copie.Name);
%      get_param('deux', 'StopTime')            % '7'
%      bdclose('all');
%
%   Voir aussi ATTACHCONFIGSET, SETACTIVECONFIGSET, SIMULINK.CONFIGSET.
    if nargin < 3
        renommer = false;
    end
    if ~isa(cs, 'Simulink.ConfigSet')
        error('Simulink:ConfigSet:InvalidConfigSet', ...
              'ATTACHCONFIGSETCOPY(MODEL,CS): CS must be a Simulink.ConfigSet.');
    end
    copie = copy(cs);
    if isstruct(modele)
        modele = attachConfigSet(modele, copie, renommer);
        noms = getConfigSets(modele);
        varargout = {modele, getConfigSet(modele, noms{end})};
    else
        attachConfigSet(modele, copie, renommer);
        varargout = {copie};
    end
end
