function poignees = findBlocksOfType(systeme, type, varargin)
%SIMULINK.FINDBLOCKSOFTYPE Les blocs d'un type dans un système.
%   H = SIMULINK.FINDBLOCKSOFTYPE(SYSTEME,TYPE) rend en colonne les
%   poignées des blocs dont le BlockType est TYPE — 'Gain', 'Sum',
%   'SubSystem' —, à tous les niveaux du système.
%   H = SIMULINK.FINDBLOCKSOFTYPE(SYSTEME,TYPE,'Param',VALEUR,...,OPTIONS)
%   filtre de plus sur des paramètres, et cherche selon un
%   Simulink.FindOptions.
%
%   Exemple :
%      bdclose('all');
%      new_system('essai');
%      add_block('built-in/Gain', 'essai/g');
%      add_block('built-in/Constant', 'essai/c');
%      getfullname(Simulink.findBlocksOfType('essai', 'Gain'))   % 'essai/g'
%      bdclose('all');
%
%   Voir aussi SIMULINK.FINDBLOCKS, SIMULINK.FINDOPTIONS, FIND_SYSTEM.
    poignees = Simulink.findBlocks(systeme, 'BlockType', char(type), varargin{:});
end
