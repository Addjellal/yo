function arrangeSystem(systeme)
%SIMULINK.BLOCKDIAGRAM.ARRANGESYSTEM Range les blocs d'un système.
%   SIMULINK.BLOCKDIAGRAM.ARRANGESYSTEM(SYSTEME) donne à chaque bloc du
%   système — un modèle chargé ou l'un de ses sous-systèmes — une place
%   (Position), par couches de gauche à droite dans le sens des signaux ;
%   la simulation n'en change pas.
%
%   Exemple :
%      new_system('aRanger');
%      add_block('built-in/Constant', 'aRanger/c');
%      add_block('built-in/Gain', 'aRanger/k');
%      add_line('aRanger', 'c/1', 'k/1');
%      Simulink.BlockDiagram.arrangeSystem('aRanger');
%      p = get_param('aRanger/k', 'Position');
%      p(1) > 0                                 % une place a droite de c
%      bdclose('aRanger');
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM, SET_PARAM.
    chemin = matlibre_sl_memoire('chemin', systeme);
    matlibre_sl_memoire('appliquer', chemin, @(s) matlibre_sl_schema('ranger', s));
end
