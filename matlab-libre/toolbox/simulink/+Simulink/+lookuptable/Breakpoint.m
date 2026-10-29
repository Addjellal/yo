classdef Breakpoint
%BREAKPOINT Les points de rupture d'une dimension d'une table.
%   B = SIMULINK.LOOKUPTABLE.BREAKPOINT ; B.Value porte les points de
%   rupture, strictement croissants, autant que la table a d'éléments sur
%   cette dimension. Min, Max, DataType, Unit, FieldName et Description
%   les décrivent ; TunableSizeName nomme leur nombre dans le code généré.
%
%   Exemple :
%      b = Simulink.lookuptable.Breakpoint;
%      b.Value = [0 1 2 3];
%      numel(b.Value)                     % 4
%
%   Voir aussi SIMULINK.LOOKUPTABLE, SIMULINK.BREAKPOINT,
%   SIMULINK.LOOKUPTABLE.EVENSPACING.
    properties
        Value = []
        Min = []
        Max = []
        DataType = 'auto'
        Unit = ''
        FieldName = 'BP'
        Description = ''
        TunableSizeName = ''
    end
    methods
        function b = set.Value(b, v)
            if ~(isnumeric(v) || islogical(v)) || ~isreal(v) || (~isempty(v) && ~isvector(v))
                error('Simulink:Data:BreakpointInvalidValue', ...
                      'Les points de rupture forment un vecteur de nombres reels.');
            end
            b.Value = v;
        end
    end
end
