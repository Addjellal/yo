function H = ezmesh(fonction, intervalle)
%EZMESH Trace le maillage d'une surface (nom historique).
%   EZMESH(F) fait ce que fait EZSURF, en dessinant le quadrillage. Le
%   rendu de MatLibre étant plan, les deux donnent la même image.
%
%   EZMESH(F,[A B]) ou EZMESH(F,[A B C D]) fixe le domaine.
%
%   H = EZMESH(...) rend la poignée.
%
%   Exemples :
%      ezmesh('x^2 - y^2');
%      ezmesh(@(x, y) exp(-x.^2 - y.^2), [-2 2]);
%
%   Voir aussi EZSURF, FMESH, EZCONTOUR, MESH.
    if nargin < 2
        intervalle = [];
    end
    H = ezsurf(fonction, intervalle);
    if nargout == 0
        clear H;
    end
end
