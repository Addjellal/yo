classdef LumiereEssai < Simulink.IntEnumType
%LUMIEREESSAI Une énumération de Simulink à membre par défaut, pour l'essai.
%   Son membre par défaut est Vert : celui que rend getDefaultValue, et
%   non le premier.
    enumeration
        Rouge(1)
        Vert(2)
        Orange(3)
    end
    methods (Static)
        function d = getDefaultValue()
            d = LumiereEssai.Vert;
        end
    end
end
