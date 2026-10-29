classdef Table
%TABLE Les valeurs d'un Simulink.LookupTable, et ce qui les décrit.
%   T = SIMULINK.LOOKUPTABLE.TABLE ; T.Value porte les valeurs de la
%   table — un vecteur pour une table à une dimension, une matrice ou un
%   tableau à N dimensions sinon, une dimension par point de rupture.
%   Min et Max les bornent, vides par défaut ; DataType, Unit, FieldName
%   et Description les décrivent.
%
%   Exemple :
%      t = Simulink.lookuptable.Table;
%      t.Value = [0 1 4 9];
%      t.FieldName                        % 'Table'
%
%   Voir aussi SIMULINK.LOOKUPTABLE, SIMULINK.LOOKUPTABLE.BREAKPOINT.
    properties
        Value = []
        Min = []
        Max = []
        DataType = 'auto'
        Unit = ''
        FieldName = 'Table'
        Description = ''
    end
    methods
        function t = set.Value(t, v)
            if ~(isnumeric(v) || islogical(v)) || ~isreal(v)
                error('Simulink:Data:LookupTableInvalidValue', ...
                      'Les valeurs d''une table sont des nombres reels ; pas %s.', class(v));
            end
            t.Value = v;
        end
        function t = set.FieldName(t, v)
            t.FieldName = nomDeChamp(v);
        end
    end
end

function v = nomDeChamp(v)
    if isstring(v) && isscalar(v)
        v = char(v);
    end
    if ~ischar(v) || ~isvarname(v)
        error('Simulink:Data:LookupTableInvalidFieldName', ...
              'FieldName est un nom de champ de structure valide.');
    end
end
