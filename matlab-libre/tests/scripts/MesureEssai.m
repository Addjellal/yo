classdef MesureEssai
%MESUREESSAI Une classe d'essai : une propriété calculée par son accesseur.
%   Sert à TEST_CLASSES : dans un tableau d'objets, « {m.Carre} » réunit
%   la propriété dépendante de chacun.
    properties
        Valeur = 0
    end
    properties (Dependent)
        Carre
    end
    methods
        function m = MesureEssai(v)
            if nargin > 0
                m.Valeur = v;
            end
        end
        function c = get.Carre(m)
            c = m.Valeur ^ 2;
        end
    end
end
