classdef CouleurEssai
%COULEURESSAI Une classe a enumeration, pour l'essai.
    properties
        code = 0
    end
    events
        Change
        Efface
    end
    enumeration
        Rouge
        Vert
        Bleu
    end
    methods
        function o = CouleurEssai(c)
            if nargin > 0, o.code = c; end
        end
        function r = doublerCouleur(o)
            r = 2 * o.code;
        end
    end
end
