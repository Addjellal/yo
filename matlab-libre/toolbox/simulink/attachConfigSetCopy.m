function copie = attachConfigSetCopy(modele, cs, renommer)
%ATTACHCONFIGSETCOPY Attache à un modèle une copie d'un jeu de configuration.
%   COPIE = ATTACHCONFIGSETCOPY(MODELE,CS) attache au modèle chargé une
%   copie de CS — attaché ailleurs ou non — et la rend. Avec
%   ATTACHCONFIGSETCOPY(MODELE,CS,true), un nom déjà pris est remplacé par
%   un nom libre.
%
%   Exemple :
%      new_system('source'); new_system('cible');
%      set_param('source', 'Solver', 'ode23');
%      cs = getActiveConfigSet('source');
%      copie = attachConfigSetCopy('cible', cs, true);
%      copie.Name                              % 'Configuration1'
%      get_param(copie, 'Solver')              % 'ode23'
%      bdclose('source'); bdclose('cible');
%
%   Voir aussi ATTACHCONFIGSET, SETACTIVECONFIGSET, SIMULINK.CONFIGSET.
    if nargin < 3
        renommer = false;
    end
    if ~isa(cs, 'Simulink.ConfigSet') || ~isscalar(cs)
        error('Simulink:ConfigSet:InvalidConfigSet', ...
              'ATTACHCONFIGSETCOPY attache la copie d''un Simulink.ConfigSet.');
    end
    copie = matlibre_sl_jeux('attacher', modele, copy(cs), logical(renommer));
end
