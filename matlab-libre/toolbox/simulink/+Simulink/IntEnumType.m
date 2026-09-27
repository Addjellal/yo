classdef IntEnumType < int32
%INTENUMTYPE Le parent des énumérations de Simulink.
%   Une énumération qui dérive de Simulink.IntEnumType a des membres de
%   valeurs entières (int32). Simulink s'en sert comme type de données :
%   un signal « Enum: Couleur » porte des membres de Couleur. Son membre
%   par défaut est le premier, sauf si la classe définit la méthode
%   statique getDefaultValue.
%
%   Exemple :
%      classdef Couleur < Simulink.IntEnumType
%          enumeration
%              Rouge(1), Vert(2), Bleu(3)
%          end
%      end
%      c = Couleur.Vert;
%      int32(c)                    % 2
%
%   Voir aussi ENUMERATION, ISENUM.
    methods (Static)
        function t = getDescription()
            %GETDESCRIPTION La description du type, vide par défaut.
            t = '';
        end
        function t = getHeaderFile()
            %GETHEADERFILE Le fichier d'en-tête du type, vide par défaut.
            t = '';
        end
        function oui = addClassNameToEnumNames()
            %ADDCLASSNAMETOENUMNAMES Faux : les noms de membres restent courts.
            oui = false;
        end
    end
end
