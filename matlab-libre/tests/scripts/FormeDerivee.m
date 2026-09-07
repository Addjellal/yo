classdef FormeDerivee < FormeDeBase
%FORMEDERIVEE Derivee de FORMEDEBASE, pour l'essai d'heritage.
%   Elle appelle le constructeur du parent, ajoute une propriete, garde
%   AIRE et PERIMETRE tels quels, et redefinit QUISUISJE.
    properties
        hauteur = 2
    end
    methods
        function o = FormeDerivee(c, h)
            o@FormeDeBase(c);
            if nargin > 1, o.hauteur = h; end
        end
        function v = volume(o)
            v = aire(o) * o.hauteur;
        end
        function n = quiSuisJe(o)   %#ok<MANU>
            n = 'derivee';
        end
    end
end
