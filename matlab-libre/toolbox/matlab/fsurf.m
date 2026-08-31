function H = fsurf(fonction, intervalle, varargin)
%FSURF Trace une surface donnée par une poignée.
%   FSURF(F) trace F sur le carré [-5 5] x [-5 5]. F est une poignée de
%   deux variables, F(X,Y).
%
%   FSURF(F,[A B]) emploie le carré [A B] x [A B].
%   FSURF(F,[A B C D]) emploie le rectangle [A B] x [C D].
%
%   FSURF(...,'MeshDensity',N) change la finesse de la grille, 40 par
%   défaut.
%
%   H = FSURF(...) rend la poignée.
%
%   Le rendu de MatLibre est plan : la surface est montrée comme un champ
%   coloré, à la façon de PCOLOR. FCONTOUR en donne les lignes de niveau,
%   souvent plus lisible.
%
%   Exemples :
%      fsurf(@(x, y) x .* exp(-x.^2 - y.^2), [-2 2]);
%      fsurf(@(x, y) sin(x) .* cos(y), [-pi pi -pi pi]);
%
%   Voir aussi SURF, FCONTOUR, FMESH, FPLOT, EZSURF, MESHGRID.
    if nargin < 2 || isempty(intervalle)
        intervalle = [-5 5 -5 5];
    end
    if numel(intervalle) == 2
        intervalle = [intervalle, intervalle];
    end
    densite = 40;
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'meshdensity')
            densite = varargin{k + 1};
        end
        k = k + 2;
    end
    [X, Y] = meshgrid(linspace(intervalle(1), intervalle(2), densite), ...
                      linspace(intervalle(3), intervalle(4), densite));
    Z = matlibre_evaluer_grille(fonction, X, Y);
    H = surf(X, Y, Z);
    if nargout == 0
        clear H;
    end
end
