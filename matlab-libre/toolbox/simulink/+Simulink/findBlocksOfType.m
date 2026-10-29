function h = findBlocksOfType(systeme, type, varargin)
%FINDBLOCKSOFTYPE Les blocs d'un type, dans un système, en poignées.
%   H = SIMULINK.FINDBLOCKSOFTYPE(SYSTEME,TYPE) rend la colonne des
%   poignées des blocs de SYSTEME dont le BlockType vaut TYPE — 'Gain',
%   'SubSystem', 'Inport'... —, à toutes les profondeurs.
%   SIMULINK.FINDBLOCKSOFTYPE(SYSTEME,TYPE,'Param',VALEUR,...,OPTIONS)
%   y ajoute des critères et un SIMULINK.FINDOPTIONS.
%
%   Exemple :
%      new_system('typesBlocs');
%      add_block('built-in/Gain', 'typesBlocs/g1');
%      add_block('built-in/Gain', 'typesBlocs/g2');
%      numel(Simulink.findBlocksOfType('typesBlocs', 'Gain'))   % 2
%      close_system('typesBlocs', 0);
%
%   Voir aussi SIMULINK.FINDBLOCKS, SIMULINK.FINDOPTIONS, FIND_SYSTEM.
    if nargin < 2 || ~(ischar(type) || (isstring(type) && isscalar(type))) || isempty(char(type))
        error('Simulink:Commands:FindBlocksArguments', ...
              'SIMULINK.FINDBLOCKSOFTYPE(SYSTEME,TYPE) : TYPE est un BlockType, ''Gain''.');
    end
    h = matlibre_sl_chercher(systeme, char(type), varargin);
end
