function modele = attachConfigSet(modele, cs, renommer)
%ATTACHCONFIGSET Attache un jeu de configuration à un modèle.
%   ATTACHCONFIGSET(MODELE,CS) attache le Simulink.ConfigSet CS au modèle
%   de la session nommé MODELE : le jeu lui est lié dès lors, sans être
%   actif — SETACTIVECONFIGSET l'active. Un jeu du même nom est refusé ;
%   ATTACHCONFIGSET(MODELE,CS,true) renomme alors CS ('Rapide1').
%
%   MODELE = ATTACHCONFIGSET(MODELE,CS) fait de même sur un modèle par
%   valeur, et le rend ; le jeu y est recopié.
%
%   Exemple :
%      m = new_system('essai');
%      cs = Simulink.ConfigSet;
%      cs.Name = 'Rapide';
%      set_param(cs, 'StopTime', '1');
%      m = attachConfigSet(m, cs);
%      getConfigSets(m)                         % {'Configuration'; 'Rapide'}
%
%   Voir aussi ATTACHCONFIGSETCOPY, SETACTIVECONFIGSET, DETACHCONFIGSET,
%   SIMULINK.CONFIGSET.
    if nargin < 3
        renommer = false;
    end
    if ~isa(cs, 'Simulink.ConfigSet')
        error('Simulink:ConfigSet:InvalidConfigSet', ...
              'ATTACHCONFIGSET(MODELE,CS) : CS est un Simulink.ConfigSet.');
    end
    parNom = ~isstruct(modele);
    if parNom
        [modele, nomModele] = matlibre_sl_nomme('modele', modele);
    end
    if parNom && ~isempty(cs.getModel())
        error('Simulink:ConfigSet:ConfigSetAlreadyAttached', ...
              ['Le jeu ''%s'' est deja attache au modele ''%s'' : ATTACHCONFIGSETCOPY ' ...
               'en attache une copie.'], cs.Name, cs.getModel());
    end
    [modele, nom] = matlibre_sl_jeux('attacher', modele, cs.structure(), ...
                                     isequal(renommer, true) || isequal(renommer, 1));
    if parNom
        matlibre_sl_nomme('ranger', nomModele, modele);
        cs.Nom = nom;
        cs.Modele = nomModele;
        clear modele
    end
end
