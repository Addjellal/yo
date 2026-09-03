classdef CompteurAReference < handle
%COMPTEURAREFERENCE Compteur à référence, pour les tests.
%   Une classe « handle » : ses copies désignent le même objet, si bien
%   qu'une méthode qui écrit dans l'objet se voit depuis toutes.
%
%   Exemple :
%      c = CompteurAReference();
%      c.incrementer();
%      c.n        % 1
    properties
        n = 0
    end
    methods
        function incrementer(obj)
            obj.n = obj.n + 1;
        end
    end
end
