classdef AliasType
%ALIASTYPE Un autre nom pour un type de données.
%   T = SIMULINK.ALIASTYPE('int16') rend un alias dont le type de base est
%   int16 ; SIMULINK.ALIASTYPE() en rend un sur double. Rangé sous un nom
%   dans l'espace de travail, l'alias se donne aux blocs par ce nom —
%   OutDataTypeStr = 'Vitesse' —, et vaut son type de base : un type
%   intégré, 'fixdt(1,16,8)', le nom d'un Simulink.NumericType ou d'un
%   autre alias.
%
%   Propriétés : BaseType ('double'), Description, DataScope ('Auto') et
%   HeaderFile, qui ne servent qu'au code produit.
%
%   Exemple :
%      Vitesse = Simulink.AliasType('int16');
%      Vitesse.BaseType               % 'int16'
%
%   Voir aussi SIMULINK.NUMERICTYPE, FIXDT.
    properties
        Description = ''
        DataScope = 'Auto'
        HeaderFile = ''
        BaseType = 'double'
    end
    methods
        function T = AliasType(base)
            if nargin > 0
                if ~(ischar(base) || isstring(base))
                    error('Simulink:DataType:AliasBaseType', ...
                          ['Le type de base d''un Simulink.AliasType est un nom de type, ' ...
                           'en texte : ''int16'', ''fixdt(1,16,8)''.']);
                end
                T.BaseType = char(base);
            end
        end
        function T = set.BaseType(T, base)
            if ~(ischar(base) || isstring(base))
                error('Simulink:DataType:AliasBaseType', ...
                      ['Le type de base d''un Simulink.AliasType est un nom de type, en ' ...
                       'texte : ''int16'', ''fixdt(1,16,8)''.']);
            end
            T.BaseType = char(base);
        end
        function disp(T)
            fprintf(['  AliasType with properties:\n\n    Description: ''%s''\n' ...
                     '      DataScope: ''%s''\n     HeaderFile: ''%s''\n' ...
                     '       BaseType: ''%s''\n\n'], T.Description, T.DataScope, ...
                    T.HeaderFile, T.BaseType);
        end
    end
end
