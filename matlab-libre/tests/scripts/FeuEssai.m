classdef FeuEssai
%FEUESSAI Une énumération dont les membres passent par le constructeur.
    properties
        Duree
    end
    methods
        function f = FeuEssai(d)
            f.Duree = d;
        end
    end
    enumeration
        Rouge (30)
        Orange (5)
        Vert (25)
    end
end
