function H = ezmesh(fonction, intervalle)
%EZMESH Trace le maillage d'une surface (nom historique).
%   EZMESH(F) fait ce que fait EZSURF, en dessinant le maillage — faces
%   blanches, arêtes colorées, comme MESH — plutôt que la surface pleine.
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
    set(H, 'FaceColor', 'w', 'EdgeColor', 'flat');
    if nargout == 0
        clear H;
    end
end
