classdef FormeDeBase
%FORMEDEBASE Classe de base pour l'essai d'heritage.
%   Elle porte une propriete, une methode ordinaire et une methode que la
%   derivee redefinit. Elle sert a verifier qu'une derivee recoit bien les
%   trois, et que la redefinition l'emporte.
    properties
        cote = 1
        nomDeBase = 'base'
    end
    methods
        function o = FormeDeBase(c)
            if nargin > 0, o.cote = c; end
        end
        function a = aire(o)
            a = o.cote ^ 2;
        end
        function p = perimetre(o)
            p = 4 * o.cote;
        end
        function n = quiSuisJe(o)   %#ok<MANU>
            n = 'base';
        end
    end
end
