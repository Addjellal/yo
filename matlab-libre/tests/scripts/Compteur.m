classdef Compteur
    properties
        valeur = 0
        pas = 1
    end
    methods
        function obj = Compteur(depart)
            if nargin > 0
                obj.valeur = depart;
            end
        end
        function obj = incrementer(obj)
            obj.valeur = obj.valeur + obj.pas;
        end
        function r = plus(a, b)
            r = Compteur(a.valeur + b.valeur);
        end
        function t = versTexte(obj)
            t = sprintf('Compteur(%g)', obj.valeur);
        end
    end
end
