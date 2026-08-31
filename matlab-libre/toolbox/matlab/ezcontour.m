function H = ezcontour(fonction, intervalle)
%EZCONTOUR Lignes de niveau d'une fonction (nom historique).
%   EZCONTOUR(F) trace les lignes de niveau de F sur
%   [-2*pi 2*pi] x [-2*pi 2*pi]. F est une poignée de deux variables, ou
%   une chaîne comme 'x^2 + y^2'.
%
%   EZCONTOUR(F,[A B]) ou EZCONTOUR(F,[A B C D]) fixe le domaine.
%
%   H = EZCONTOUR(...) rend la poignée.
%
%   Depuis R2016b, MATLAB recommande FCONTOUR ; MatLibre garde les deux.
%
%   Exemples :
%      ezcontour('x^2 + y^2');
%      ezcontour(@(x, y) sin(x) + cos(y), [-pi pi]);
%
%   Voir aussi FCONTOUR, CONTOUR, EZSURF, EZPLOT.
    if nargin < 2 || isempty(intervalle)
        intervalle = [-2 * pi, 2 * pi];
    end
    if ischar(fonction) || isstring(fonction)
        fonction = matlibre_poignee_depuis_texte(char(fonction));
    end
    H = fcontour(fonction, intervalle);
    if nargout == 0
        clear H;
    end
end
