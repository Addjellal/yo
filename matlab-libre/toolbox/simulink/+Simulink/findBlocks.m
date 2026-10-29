function h = findBlocks(systeme, varargin)
%FINDBLOCKS Les blocs d'un système, en poignées.
%   H = SIMULINK.FINDBLOCKS(SYSTEME) rend la colonne des poignées des blocs
%   de SYSTEME — un modèle ou un sous-système chargé, par son chemin ou sa
%   poignée —, à toutes les profondeurs, le système lui-même exclu.
%   H = SIMULINK.FINDBLOCKS(SYSTEME,'Param',VALEUR,...) ne garde que les
%   blocs dont les paramètres valent ces valeurs ;
%   SIMULINK.FINDBLOCKS(...,OPTIONS) applique un SIMULINK.FINDOPTIONS.
%   Sans SYSTEME — SIMULINK.FINDBLOCKS() — : les blocs de tous les
%   modèles chargés.
%
%   Exemple :
%      new_system('trouverBlocs');
%      add_block('built-in/Gain', 'trouverBlocs/g', 'Gain', '2');
%      add_block('built-in/Constant', 'trouverBlocs/c');
%      h = Simulink.findBlocks('trouverBlocs', 'BlockType', 'Gain');
%      getfullname(h)                     % 'trouverBlocs/g'
%      close_system('trouverBlocs', 0);
%
%   Voir aussi SIMULINK.FINDBLOCKSOFTYPE, SIMULINK.FINDOPTIONS, FIND_SYSTEM.
    if nargin == 0
        systeme = matlibre_sl_ouverts('noms');
    end
    h = matlibre_sl_chercher(systeme, '', varargin);
end
