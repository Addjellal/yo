function H = fimplicit(fonction, intervalle)
%FIMPLICIT Courbe implicite F(x,y) = 0.
%   FIMPLICIT(F) trace l'ensemble des points où F s'annule, sur
%   [-5 5] x [-5 5]. F est une poignée de deux variables.
%
%   FIMPLICIT(F,[A B]) emploie le carré [A B] x [A B].
%   FIMPLICIT(F,[A B C D]) emploie le rectangle donné.
%
%   H = FIMPLICIT(...) rend la poignée.
%
%   La courbe est obtenue comme la ligne de niveau zéro de F, par la même
%   méthode que CONTOUR : c'est exactement ce qu'est une courbe
%   implicite.
%
%   Exemples :
%      fimplicit(@(x, y) x.^2 + y.^2 - 1);              % le cercle unite
%      fimplicit(@(x, y) x.^3 + y.^3 - 3*x.*y, [-3 3]); % le folium
%      fimplicit(@(x, y) y.^2 - x.^3 + x, [-2 3]);      % une cubique
%
%   Voir aussi FCONTOUR, CONTOUR, FPLOT, EZPLOT, FSURF.
    if nargin < 2 || isempty(intervalle)
        intervalle = [-5 5 -5 5];
    end
    if numel(intervalle) == 2
        intervalle = [intervalle, intervalle];
    end
    densite = 200;
    [X, Y] = meshgrid(linspace(intervalle(1), intervalle(2), densite), ...
                      linspace(intervalle(3), intervalle(4), densite));
    Z = matlibre_evaluer_grille(fonction, X, Y);
    [~, H] = contour(X, Y, Z, [0 0]);
    if nargout == 0
        clear H;
    end
end
