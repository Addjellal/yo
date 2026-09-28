classdef SlDemoSign < Simulink.IntEnumType
%SLDEMOSIGN Le signe d'un nombre, en énumération : l'exemple de Simulink.
%   Le type que le bloc Enumerated Constant propose d'emblée : ses membres
%   sont Positive (1), Zero (0) et Negative (-1), et un signal de type
%   « Enum: SlDemoSign » porte l'un d'eux.
%
%   Exemple :
%      s = SlDemoSign.Negative;
%      int32(s)                    % -1
%
%   Voir aussi SIMULINK.INTENUMTYPE, ENUMERATION.
    enumeration
        Positive(1)
        Zero(0)
        Negative(-1)
    end
end
