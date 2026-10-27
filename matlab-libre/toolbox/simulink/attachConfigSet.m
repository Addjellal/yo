function attachConfigSet(modele, cs, renommer)
%ATTACHCONFIGSET Attache un jeu de configuration à un modèle.
%   ATTACHCONFIGSET(MODELE,CS) attache le Simulink.ConfigSet CS, détaché, au
%   modèle chargé MODELE ; il n'en devient pas le jeu actif —
%   SETACTIVECONFIGSET l'active. Un nom déjà pris parmi les jeux du modèle
%   est refusé, sauf avec ATTACHCONFIGSET(MODELE,CS,true), qui en choisit
%   un libre (Rapide1, Rapide2...). Un jeu déjà attaché à un modèle l'est
%   pour de bon : ATTACHCONFIGSETCOPY en attache une copie.
%
%   Exemple :
%      new_system('attache');
%      cs = Simulink.ConfigSet;
%      cs.Name = 'Precis';
%      set_param(cs, 'RelTol', '1e-8');
%      attachConfigSet('attache', cs);
%      setActiveConfigSet('attache', 'Precis');
%      get_param('attache', 'RelTol')           % '1e-8'
%      bdclose('attache');
%
%   Voir aussi ATTACHCONFIGSETCOPY, SETACTIVECONFIGSET, DETACHCONFIGSET,
%   SIMULINK.CONFIGSET.
    if nargin < 3
        renommer = false;
    end
    matlibre_sl_jeux('attacher', modele, cs, logical(renommer));
end
