function H = fmesh(fonction, intervalle, varargin)
%FMESH Trace le maillage d'une surface donnée par une poignée.
%   FMESH(F) fait ce que fait FSURF, en dessinant le quadrillage plutôt
%   que la surface pleine. Le rendu de MatLibre étant plan, les deux
%   donnent la même image.
%
%   FMESH(F,[A B]) et FMESH(F,[A B C D]) fixent le domaine, comme FSURF.
%   FMESH(...,'MeshDensity',N) change la finesse de la grille.
%
%   H = FMESH(...) rend la poignée.
%
%   Exemples :
%      fmesh(@(x, y) x.^2 - y.^2, [-2 2]);
%
%   Voir aussi FSURF, FCONTOUR, MESH, FPLOT, EZMESH.
    if nargin < 2
        intervalle = [];
    end
    H = fsurf(fonction, intervalle, varargin{:});
    if nargout == 0
        clear H;
    end
end
